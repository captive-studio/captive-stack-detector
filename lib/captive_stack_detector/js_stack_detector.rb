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
        type:     type,
        subtype:  nil,
        services: Services.new(database: nil, queue: nil),
        worker:   nil,
        runtime:  Runtime.new(ruby: nil, node: @reader.node_version),
        env_vars: {},
      )
    end
  end
end
