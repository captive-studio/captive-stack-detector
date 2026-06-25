# frozen_string_literal: true

require "json"
require_relative "captive_stack_detector/types"
require_relative "captive_stack_detector/file_reader"
require_relative "captive_stack_detector/gemfile_analyzer"
require_relative "captive_stack_detector/rails_stack_detector"
require_relative "captive_stack_detector/js_stack_detector"

module CaptiveStackDetector
  def self.detect(local_path: nil, github_token: nil, repo: nil)
    reader = FileReader.build(local_path: local_path, github_token: github_token, repo: repo)
    detect_from(reader)
  end

  def self.detect_from(reader)
    gemfile      = reader.read("Gemfile")
    package_json = reader.read("package.json")

    return RailsStackDetector.new(reader, GemfileAnalyzer.new(gemfile)).detect if gemfile
    return JsStackDetector.new(reader, package_json).detect                    if package_json

    raise UnsupportedStack
  end
  private_class_method :detect_from
end
