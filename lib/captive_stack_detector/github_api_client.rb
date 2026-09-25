# frozen_string_literal: true

require "net/http"
require "uri"
require "base64"
require "json"
require_relative "github_tree"

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
    rescue StandardError
      nil
    end

    def list(dir)
      body = get("git/trees/HEAD?recursive=1")
      return [] unless body

      GithubTree.new(body).files_in(dir)
    rescue StandardError
      []
    end

    private

    def get(path)
      uri = URI("https://api.github.com/repos/#{@repo}/#{path}")
      req = Net::HTTP::Get.new(uri, "Authorization" => "Bearer #{@token}", "Accept" => "application/vnd.github+json")
      res = Net::HTTP.start(uri.host, uri.port, use_ssl: true) { |http| http.request(req) }
      res.body if res.is_a?(Net::HTTPSuccess)
    end
  end
end
