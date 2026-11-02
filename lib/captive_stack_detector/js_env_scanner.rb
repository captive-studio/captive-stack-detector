# frozen_string_literal: true

require_relative "js_env_lexer"

module CaptiveStackDetector
  # Ne demande que les lectures sans valeur de repli et hors variables intégrées.
  module JsEnvScanner
    DEFAULT = /\A\s*(?:\?\?|\|\|)\s*(?:"(?:\\.|[^"\\])*"|'(?:\\.|[^'\\])*'|true\b|false\b|\d+(?:\.\d+)?\b)/
    ASSIGNMENT = /\A\s*(?:=(?!=|>)|\?\?=|\|\|=|&&=)/
    RUNTIME_VARS = %w[NODE_ENV NODE_OPTIONS PORT HOST].freeze
    VITE_VARS = %w[BASE_URL MODE DEV PROD SSR].freeze

    def self.scan(content)
      JsEnvLexer.new(content).references.each_with_object({}) do |(key, scope, rest), found|
        next if RUNTIME_VARS.include?(key) || (scope == "vite" && VITE_VARS.include?(key))
        next if DEFAULT.match?(rest) || ASSIGNMENT.match?(rest)

        found[key] = "placeholder"
      end
    end
  end
end
