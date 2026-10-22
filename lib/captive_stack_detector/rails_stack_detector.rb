# frozen_string_literal: true

require_relative "../captive_stack_detector"
require_relative "system_package_detector"
require_relative "solid_queue_worker"

module CaptiveStackDetector
  # Construit le Result d'une app Rails à partir des fichiers du repo.
  class RailsStackDetector
    def initialize(reader, analyzer)
      @reader   = reader
      @analyzer = analyzer
    end

    def detect
      raise UnsupportedStack, :no_rails unless @analyzer.rails?

      Result.new(
        type:            "rails",
        subtype:         @analyzer.subtype,
        services:        Services.new(database: @analyzer.database, queue: @analyzer.queue, backend: nil),
        worker:          build_worker,
        runtime:         Runtime.new(ruby: @reader.ruby_version, node: nil),
        env_vars:        @reader.env_vars,
        system_packages: system_packages,
      )
    end

    private

    def build_worker
      command = @analyzer.worker_command(@reader.read("Procfile")) || SolidQueueWorker.new(@reader, @analyzer).command
      command ? Worker.new(command: command) : nil
    end

    def system_packages
      SystemPackageDetector.new(
        gemfile:  @reader.read("Gemfile"),
        aptfile:  @reader.read("Aptfile"),
        lockfile: @reader.read("Gemfile.lock"),
      ).packages
    end
  end
end
