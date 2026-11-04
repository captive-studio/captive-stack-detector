# frozen_string_literal: true

require_relative "types"

module CaptiveStackDetector
  # Un site statique sans manifeste ni build (index.html qui charge ses scripts) : stack node
  # sans subtype, servie telle quelle. Supabase (et sa base Postgres) se reconnaît à son dossier, faute de package.json.
  class StaticSiteDetector
    ENTRIES = %w[public/index.html index.html].freeze
    NO_RUNTIME = Runtime.new(ruby: nil, node: nil)
    NO_SERVICES = Services.new(database: nil, queue: nil, backend: nil)
    # Supabase repose sur Postgres, comme le déduit PackageJsonAnalyzer pour une stack Node.
    SUPABASE = Services.new(database: "postgres", queue: nil, backend: "supabase")

    def initialize(reader)
      @reader = reader
    end

    def site?
      ENTRIES.any? { |entry| @reader.read(entry) }
    end

    def detect
      Result.new(
        type: "node", subtype: nil, worker: nil, env_vars: {}, system_packages: [],
        services: @reader.read("supabase/config.toml") ? SUPABASE : NO_SERVICES,
        runtime: NO_RUNTIME,
      )
    end
  end
end
