# frozen_string_literal: true

module CaptiveStackDetector
  Result = Struct.new(:type, keyword_init: true)
  UnsupportedStack = Class.new(StandardError)

  def self.detect(gemfile: nil, package_json: nil, procfile: nil)
    return detect_rails(gemfile) if gemfile
    return detect_js(package_json) if package_json

    raise UnsupportedStack
  end

  def self.detect_rails(gemfile)
    raise UnsupportedStack unless gemfile.match?(/gem ['"]rails['"]/)

    Result.new(type: "rails")
  end
  private_class_method :detect_rails

  def self.detect_js(package_json)
    type = package_json.include?('"expo"') ? "expo" : "node"
    Result.new(type: type)
  end
  private_class_method :detect_js
end
