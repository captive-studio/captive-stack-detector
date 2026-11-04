# frozen_string_literal: true

module CaptiveStackDetector
  Services = Data.define(:database, :queue, :backend)
  Worker   = Data.define(:command)
  Runtime  = Data.define(:ruby, :node)
  # public_env_prefix : préfixe des variables que le bundler expose au navigateur
  # (VITE_, NEXT_PUBLIC_, EXPO_PUBLIC_), nil sans bundler front (PackageJsonAnalyzer).
  Result   = Data.define(:type, :subtype, :services, :worker, :runtime, :env_vars, :system_packages,
                         :public_env_prefix) do
    # env_vars : { "NOM" => valeur }, fusionné par captive-admin au provisionnement.
    def initialize(env_vars:, public_env_prefix: nil, **)
      Hash.try_convert(env_vars) or raise ArgumentError, "env_vars doit être un Hash"
      super
    end
  end

  # reason : :no_manifest, :no_rails ou :no_node_entry, pour que l'appelant explique le refus.
  class UnsupportedStack < StandardError
    attr_reader :reason

    def initialize(reason = nil)
      @reason = reason
      super(reason&.to_s || "unsupported stack")
    end
  end
end
