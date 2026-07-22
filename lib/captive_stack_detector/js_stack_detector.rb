# frozen_string_literal: true

require_relative "../captive_stack_detector"
require_relative "package_json_analyzer"

module CaptiveStackDetector
  class JsStackDetector
    def initialize(reader, package_json)
      @reader   = reader
      @analyzer = PackageJsonAnalyzer.new(package_json)
    end

    def detect
      type = @analyzer.type
      raise UnsupportedStack unless type

      Result.new(
        type:            type,
        subtype:         @analyzer.subtype,
        services:        Services.new(database: @analyzer.database, queue: @analyzer.queue),
        worker:          build_worker,
        runtime:         Runtime.new(ruby: nil, node: @reader.node_version),
        env_vars:        {},
        system_packages: [],
      )
    end

    private

    def build_worker
      procfile = @reader.read("Procfile")
      return nil unless procfile

      procfile.each_line do |line|
        m = line.match(/^worker:\s*(.+)$/)
        return Worker.new(command: m[1].strip) if m
      end
      nil
    end
  end
end
