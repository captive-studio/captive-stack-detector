# frozen_string_literal: true

require "net/http"
require "uri"
require "base64"
require "json"
require_relative "github_tree"
require_relative "types"

module CaptiveStackDetector
  class GithubApiClient
    def initialize(token, repo)
      @token = token
      @repo  = repo
    end

    def fetch(filename)
      body = get("contents/#{filename}")
      return nil unless body

      Base64.decode64(JSON.parse(body)["content"]).force_encoding("utf-8")
    rescue JSON::ParserError, NoMethodError, TypeError
      nil
    end

    def list(dir)
      body = get("git/trees/HEAD?recursive=1")
      return [] unless body

      GithubTree.new(body).files_in(dir)
    rescue JSON::ParserError, NoMethodError, TypeError
      []
    end

    private

    # 404 : fichier absent ; 409 : dépôt vide. Tout autre échec vient de GitHub, pas du dépôt.
    ABSENT = [ "404", "409" ].freeze
    REFUSALS = { "401" => :unauthorized, "429" => :rate_limited }.freeze

    def get(path)
      uri = URI("https://api.github.com/repos/#{@repo}/#{path}")
      req = Net::HTTP::Get.new(uri, "Authorization" => "Bearer #{@token}", "Accept" => "application/vnd.github+json")
      res = Net::HTTP.start(uri.host, uri.port, use_ssl: true) { |http| http.request(req) }
      return res.body if res.is_a?(Net::HTTPSuccess)
      return nil if ABSENT.include?(res.code)

      raise SourceUnavailable.new(refusal_kind(res), status: res.code.to_i)
    rescue SystemCallError, IOError, SocketError, Timeout::Error, OpenSSL::SSL::SSLError => e
      raise SourceUnavailable.new(:network, detail: e.message)
    end

    # GitHub signale un quota épuisé par un 403 ou un 429, avec x-ratelimit-remaining à 0.
    def refusal_kind(res)
      return :rate_limited if res["x-ratelimit-remaining"] == "0"

      REFUSALS.fetch(res.code) { res.is_a?(Net::HTTPServerError) ? :server_error : :forbidden }
    end
  end
end
