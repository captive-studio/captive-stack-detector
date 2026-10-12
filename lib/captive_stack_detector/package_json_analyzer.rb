# frozen_string_literal: true

require "json"
require_relative "ssr_framework_detector"

module CaptiveStackDetector
  class PackageJsonAnalyzer
    PUBLIC_ENV_PREFIXES = { "expo" => "EXPO_PUBLIC_", "next" => "NEXT_PUBLIC_", "vite" => "VITE_" }.freeze
    # Des clients, pas des ORM : Prisma ou Drizzle parlent aussi MySQL et SQLite, leur
    # présence ne dit pas que l'app attend une base Postgres.
    POSTGRES_CLIENTS = %w[pg postgres].freeze
    REDIS_CLIENTS    = %w[redis ioredis].freeze
    SUPABASE_CLIENTS = %w[@supabase/supabase-js @supabase/ssr].freeze

    def initialize(package_json)
      @parsed = JSON.parse(package_json)
    end

    def type
      return "expo" if deps.key?("expo")
      # build seul : une SPA, buildée puis servie en statique
      return "node" if @parsed.dig("scripts", "start") || @parsed.dig("scripts", "build")

      nil
    end

    def subtype
      SsrFrameworkDetector.server?(deps) ? "server" : nil
    end

    def database
      return "postgres" if any_dep?(POSTGRES_CLIENTS) || backend

      nil
    end

    def queue
      any_dep?(REDIS_CLIENTS) ? "redis" : nil
    end

    def backend
      any_dep?(SUPABASE_CLIENTS) ? "supabase" : nil
    end

    # Le premier bundler trouvé, dans l'ordre du type : vite en dernier, parce qu'il arrive
    # souvent avec Vitest sans construire le front.
    def public_env_prefix
      PUBLIC_ENV_PREFIXES.find { |dependance, _| deps.key?(dependance) }&.last
    end

    private

    def any_dep?(names)
      names.any? { |name| deps.key?(name) }
    end

    def deps
      @parsed.fetch("dependencies", {}).merge(@parsed.fetch("devDependencies", {}))
    end
  end
end
