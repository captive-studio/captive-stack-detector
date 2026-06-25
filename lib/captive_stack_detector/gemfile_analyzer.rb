# frozen_string_literal: true

module CaptiveStackDetector
  class GemfileAnalyzer
    ASSET_GEMS = %w[
      sprockets sprockets-rails propshaft importmap-rails
      cssbundling-rails jsbundling-rails dartsass-rails tailwindcss-rails
    ].freeze

    REDIS_GEMS = %w[redis redis-client sidekiq].freeze

    def initialize(gemfile)
      @gemfile = gemfile
    end

    def rails?   = gem?("rails")
    def subtype  = ASSET_GEMS.any? { |g| gem?(g) } ? "app" : "api"
    def database = gem?("pg") ? "postgres" : nil
    def queue    = REDIS_GEMS.any? { |g| gem?(g) } ? "redis" : nil

    def worker_command(procfile)
      if procfile
        procfile.each_line do |line|
          m = line.match(/^worker:\s*(.+)$/)
          return m[1].strip if m
        end
      end
      gem?("sidekiq") ? "bundle exec sidekiq" : nil
    end

    private

    def gem?(name)
      @gemfile.match?(/gem ['"]#{Regexp.escape(name)}['"]/)
    end
  end
end
