# frozen_string_literal: true

require "net/http"
require "uri"
require "base64"
require "json"

module CaptiveStackDetector
  class GithubApiClient
    def initialize(token, repo)
      @token = token
      @repo  = repo
    end

    def fetch(filename)
      uri = URI("https://api.github.com/repos/#{@repo}/contents/#{filename}")
      req = Net::HTTP::Get.new(uri)
      req["Authorization"] = "Bearer #{@token}"
      req["Accept"]        = "application/vnd.github+json"

      res = Net::HTTP.start(uri.host, uri.port, use_ssl: true) { |h| h.request(req) }
      return nil unless res.is_a?(Net::HTTPSuccess)

      Base64.decode64(JSON.parse(res.body)["content"]).force_encoding("utf-8")
    rescue StandardError
      nil
    end
  end
end
