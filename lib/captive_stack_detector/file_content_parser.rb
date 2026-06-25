# frozen_string_literal: true

require_relative "env_vars_scanner"

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
      if (nvmrc = @reader.read(".nvmrc"))
        return nvmrc.strip.sub(/^v/, "").split(".").first
      end
      if (tv = @reader.read(".tool-versions"))
        m = tv.match(/^nodejs\s+(\d+)/)
        return m[1] if m
      end
      nil
    end

    def env_vars
      content = @reader.read("config/storage.yml")
      content ? EnvVarsScanner.scan(content) : {}
    end
  end
end
