# frozen_string_literal: true

require_relative "env_vars_scanner"
require_relative "node_version_detector"
require_relative "ruby_version_detector"

module CaptiveStackDetector
  class FileContentParser
    def initialize(reader)
      @reader = reader
    end

    def ruby_version
      RubyVersionDetector.new(@reader).detect
    end

    def node_version
      NodeVersionDetector.new(@reader).detect
    end

    def env_vars
      content = @reader.read("config/storage.yml")
      content ? EnvVarsScanner.scan(content) : {}
    end
  end
end
