# frozen_string_literal: true

require "json"
require_relative "ssr_framework_detector"

module CaptiveStackDetector
  class PackageJsonAnalyzer
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
      return "node" if @parsed.dig("scripts", "start")

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

    private

    def any_dep?(names)
      names.any? { |name| deps.key?(name) }
    end

    def deps
      @parsed.fetch("dependencies", {}).merge(@parsed.fetch("devDependencies", {}))
    end
  end
end
