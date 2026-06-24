# frozen_string_literal: true

module CaptiveStackDetector
  class GemfileAnalyzer
    ASSET_GEMS = %w[sprockets propshaft importmap-rails].freeze

    def initialize(gemfile)
      @gemfile = gemfile
    end

    def rails? = gem?("rails")
    def subtype = ASSET_GEMS.any? { |g| gem?(g) } ? "app" : "api"
    def with_postgres = gem?("pg")
    def with_redis = gem?("redis")
    def worker_command = gem?("sidekiq") ? "bundle exec sidekiq" : nil

    private

    def gem?(name)
      @gemfile.match?(/gem ['"]#{Regexp.escape(name)}['"]/)
    end
  end
end
