# frozen_string_literal: true

require "json"

module CaptiveStackDetector
  class PackageJsonAnalyzer
    def initialize(package_json)
      @parsed = JSON.parse(package_json)
    end

    def type
      return "expo" if deps.key?("expo")
      return "node" if @parsed.dig("scripts", "start")

      nil
    end

    private

    def deps
      @parsed.fetch("dependencies", {}).merge(@parsed.fetch("devDependencies", {}))
    end
  end
end
