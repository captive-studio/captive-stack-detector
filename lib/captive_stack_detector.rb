# frozen_string_literal: true

module CaptiveStackDetector
  Result = Struct.new(:type, :subtype, :with_postgres, :with_redis, :worker_command, keyword_init: true)
  UnsupportedStack = Class.new(StandardError)

  def self.detect(gemfile: nil, package_json: nil)
    return detect_rails(gemfile) if gemfile
    return detect_js(package_json) if package_json

    raise UnsupportedStack
  end

  ASSET_GEMS = %w[sprockets propshaft importmap-rails].freeze

  def self.detect_rails(gemfile)
    raise UnsupportedStack unless gem?(gemfile, "rails")

    subtype = ASSET_GEMS.any? { |g| gem?(gemfile, g) } ? "app" : "api"
    worker_command = gem?(gemfile, "sidekiq") ? "bundle exec sidekiq" : nil
    Result.new(type: "rails", subtype: subtype, with_postgres: gem?(gemfile, "pg"), with_redis: gem?(gemfile, "redis"),
               worker_command: worker_command)
  end
  private_class_method :detect_rails

  def self.gem?(gemfile, name)
    gemfile.match?(/gem ['"]#{Regexp.escape(name)}['"]/)
  end
  private_class_method :gem?

  def self.detect_js(package_json)
    type = package_json.include?('"expo"') ? "expo" : "node"
    Result.new(type: type)
  end
  private_class_method :detect_js
end
