# frozen_string_literal: true

require_relative "js_env_scanner"
require_relative "env_template_scanner"

module CaptiveStackDetector
  # Choisit les fichiers lisibles avant tout téléchargement de contenu.
  module JsEnvFiles
    TEMPLATES = %w[.env.example .env.sample .env.template].freeze
    EXCLUDED = %r{
      (?:\A|/)(?:node_modules|vendor|\.git|dist|build|\.output|\.next|\.nuxt|\.astro|coverage|
      test|tests|spec|__tests__|__mocks__|\.storybook|\.github|scripts|bin|docs|examples|fixtures|e2e)(?:/|\z)
    }x
    SOURCE = /(?<!\.test)(?<!\.spec)(?<!\.stories)(?<!\.d)\.(?:[cm]?[jt]sx?|astro|vue|svelte)\z/

    def self.parser(path)
      return nil if EXCLUDED.match?(path)
      return EnvTemplateScanner if TEMPLATES.include?(path)

      JsEnvScanner if SOURCE.match?(path)
    end
  end
end
