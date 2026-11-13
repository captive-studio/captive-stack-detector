# frozen_string_literal: true

require "net/http"
require "uri"
require "base64"
require "json"
require_relative "github_tree"
require_relative "types"
require_relative "github_response"

module CaptiveStackDetector
  class GithubApiClient
    # Un corps illisible (JSON invalide ou sans le champ attendu) vaut une absence.
    UNREADABLE = [ JSON::ParserError, NoMethodError, TypeError ].freeze

    def initialize(token, repo)
      @token = token
      @repo  = repo
    end

    def fetch(filename)
      body = get("contents/#{filename}")
      return nil unless body

      Base64.decode64(JSON.parse(body)["content"]).force_encoding("utf-8")
    rescue *UNREADABLE
      nil
    end

    def list(dir)
      body = get("git/trees/HEAD?recursive=1")
      return [] unless body

      GithubTree.new(body).files_in(dir)
    rescue *UNREADABLE
      []
    end

    private

    def get(path)
      uri = URI("https://api.github.com/repos/#{@repo}/#{path}")
      GithubResponse.body(Net::HTTP.get_response(uri, "Authorization" => "Bearer #{@token}",
                                                      "Accept" => "application/vnd.github+json"))
    rescue SystemCallError, IOError, SocketError, Timeout::Error, OpenSSL::SSL::SSLError => e
      raise SourceUnavailable.new(:network, detail: e.message)
    end
  end
end
