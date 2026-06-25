# frozen_string_literal: true

require_relative "env_vars_scanner"
require_relative "node_version_detector"

module CaptiveStackDetector
  class FileContentParser
    def initialize(reader)
      @reader = reader
    end

    def ruby_version
      content = @reader.read(".tool-versions")
      content&.match(/^ruby\s+(\S+)/)&.captures&.first
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
