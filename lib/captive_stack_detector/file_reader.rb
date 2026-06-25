# frozen_string_literal: true

require "forwardable"
require_relative "file_content_parser"
require_relative "github_api_client"

module CaptiveStackDetector
  class FileReader
    def self.build(local_path: nil, github_token: nil, repo: nil)
      return LocalFileReader.new(local_path) if local_path
      return GithubFileReader.new(github_token, repo) if github_token && repo

      raise ArgumentError, "local_path: ou github_token: + repo: requis"
    end
  end

  class LocalFileReader
    extend Forwardable

    def_delegators :@parser, :ruby_version, :node_version, :env_vars

    def initialize(path)
      @path   = path
      @parser = FileContentParser.new(self)
    end

    def read(filename)
      full = File.join(@path, filename)
      File.read(full, encoding: "utf-8") if File.exist?(full)
    end
  end

  class GithubFileReader
    extend Forwardable

    def_delegators :@parser, :ruby_version, :node_version, :env_vars

    def initialize(token, repo)
      @client = GithubApiClient.new(token, repo)
      @parser = FileContentParser.new(self)
    end

    def read(filename)
      @client.fetch(filename)
    end
  end
end
