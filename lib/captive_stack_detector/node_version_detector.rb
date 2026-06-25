# frozen_string_literal: true

require "json"

module CaptiveStackDetector
  class NodeVersionDetector
    def initialize(reader)
      @reader = reader
    end

    def detect
      return from_nvmrc    if (nvmrc = @reader.read(".nvmrc"))
      return from_tool_versions if (tv = @reader.read(".tool-versions"))
      return from_package_json  if (pkg = @reader.read("package.json"))

      nil
    end

    private

    def from_nvmrc
      @reader.read(".nvmrc").strip.sub(/^v/, "").split(".").first
    end

    def from_tool_versions
      m = @reader.read(".tool-versions")&.match(/^nodejs\s+(\d+)/)
      m&.[](1)
    end

    def from_package_json
      m = JSON.parse(@reader.read("package.json")).dig("engines", "node")&.match(/\d+/)
      m&.[](0)
    end
  end
end
