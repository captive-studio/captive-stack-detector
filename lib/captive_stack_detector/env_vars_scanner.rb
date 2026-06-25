# frozen_string_literal: true

module CaptiveStackDetector
  module EnvVarsScanner
    HANDLED_VARS = %w[
      RAILS_ENV SECRET_KEY_BASE DATABASE_URL REDIS_URL
      RAILS_LOG_TO_STDOUT RAILS_SERVE_STATIC_FILES PORT RACK_ENV
    ].freeze

    ENV_KEY_PATTERN      = /ENV\.fetch\(['"]([A-Z_][A-Z0-9_]*)['"]|ENV\[['"]([A-Z_][A-Z0-9_]*)['"]\]/
    SAFE_DEFAULT_PATTERN = /\A,\s*(?:nil\b|true\b|false\b|'[^']*'|"[^"]*"|\d+)\s*[,)]/
    BLOCK_DEFAULT_PATTERN = /\A\s*\)\s*(?:do|\{)/
    ASSIGNMENT_PATTERN   = /\A\s*\|\|=/

    def self.scan(content)
      result = {}
      uncommented(content).scan(ENV_KEY_PATTERN) do |fetch_key, bracket_key|
        after = Regexp.last_match.post_match
        if bracket_key
          next if ASSIGNMENT_PATTERN.match?(after)

          result[bracket_key] ||= "placeholder"
        else
          next if SAFE_DEFAULT_PATTERN.match?(after) || BLOCK_DEFAULT_PATTERN.match?(after)

          result[fetch_key] ||= "placeholder"
        end
      end
      result.reject { |k, _| HANDLED_VARS.include?(k) }
    end

    def self.uncommented(content)
      content.lines.reject { |l| l.match?(/^\s*#/) }.join
    end
    private_class_method :uncommented
  end
end
