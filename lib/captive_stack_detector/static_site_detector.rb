# frozen_string_literal: true

require_relative "types"

module CaptiveStackDetector
  # Un site statique sans manifeste ni build (index.html qui charge ses scripts) : stack node
  # sans subtype, servie telle quelle. Supabase se reconnaît à son dossier, faute de package.json.
  class StaticSiteDetector
    ENTRIES = %w[public/index.html index.html].freeze
    NO_RUNTIME = Runtime.new(ruby: nil, node: nil)

    def initialize(reader)
      @reader = reader
    end

    def site?
      ENTRIES.any? { |entry| @reader.read(entry) }
    end

    def detect
      Result.new(
        type: "node", subtype: nil, worker: nil, env_vars: {}, system_packages: [],
        services: Services.new(database: nil, queue: nil, backend: backend),
        runtime: NO_RUNTIME,
      )
    end

    private

    def backend = ("supabase" if @reader.read("supabase/config.toml"))
  end
end
