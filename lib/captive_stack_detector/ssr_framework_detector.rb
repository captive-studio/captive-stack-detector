# frozen_string_literal: true

module CaptiveStackDetector
  # Reconnaît les frameworks JS rendus côté serveur (SSR) à partir des dépendances.
  module SsrFrameworkDetector
    FRAMEWORKS = %w[next nuxt @sveltejs/kit].freeze
    SCOPES     = %w[@remix-run/].freeze

    def self.server?(deps)
      FRAMEWORKS.any? { |framework| deps.key?(framework) } ||
        deps.keys.any? { |dep| SCOPES.any? { |scope| dep.start_with?(scope) } }
    end
  end
end
