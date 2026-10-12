# frozen_string_literal: true

module CaptiveStackDetector
  Services = Data.define(:database, :queue, :backend)
  Worker   = Data.define(:command)
  Runtime  = Data.define(:ruby, :node)
  Result   = Data.define(:type, :subtype, :services, :worker, :runtime, :env_vars, :system_packages)

  # reason : :no_manifest, :no_rails ou :no_node_entry, pour que l'appelant explique le refus.
  class UnsupportedStack < StandardError
    attr_reader :reason

    def initialize(reason = nil)
      @reason = reason
      super(reason&.to_s || "unsupported stack")
    end
  end
end
