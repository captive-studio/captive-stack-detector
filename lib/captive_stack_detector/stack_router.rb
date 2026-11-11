# frozen_string_literal: true

require_relative "types"
require_relative "gemfile_analyzer"
require_relative "rails_stack_detector"
require_relative "js_stack_detector"
require_relative "static_site_detector"

module CaptiveStackDetector
  # Aiguille un dépôt vers le détecteur de sa stack, d'après ses manifestes à la racine.
  class StackRouter
    def initialize(reader)
      @reader = reader
    end

    def detect
      gemfile      = @reader.read("Gemfile")
      package_json = @reader.read("package.json")

      return RailsStackDetector.new(@reader, GemfileAnalyzer.new(gemfile)).detect if gemfile

      static_site = StaticSiteDetector.new(@reader)
      # Un package.json sans point d'entrée (Supabase CLI, prettier…) n'est que de l'outillage :
      # un index.html présent reste servi tel quel au lieu d'un refus no_node_entry.
      js = package_json && JsStackDetector.new(@reader, package_json)
      return js.detect if js && (js.entry? || !static_site.site?)
      raise UnsupportedStack, :no_manifest unless static_site.site?

      static_site.detect
    end
  end
end
