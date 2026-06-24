# frozen_string_literal: true

require_relative "captive_stack_detector/gemfile_analyzer"

module CaptiveStackDetector
  Result = Struct.new(:type, :subtype, :with_postgres, :with_redis, :worker_command, keyword_init: true)
  UnsupportedStack = Class.new(StandardError)

  def self.detect(gemfile: nil, package_json: nil)
    return detect_rails(gemfile) if gemfile
    return detect_js(package_json) if package_json

    raise UnsupportedStack
  end

  def self.detect_rails(gemfile)
    analyzer = GemfileAnalyzer.new(gemfile)
    raise UnsupportedStack unless analyzer.rails?

    Result.new(type: "rails", subtype: analyzer.subtype, with_postgres: analyzer.with_postgres,
               with_redis: analyzer.with_redis, worker_command: analyzer.worker_command)
  end
  private_class_method :detect_rails

  def self.detect_js(package_json)
    type = package_json.include?('"expo"') ? "expo" : "node"
    Result.new(type: type)
  end
  private_class_method :detect_js
end
