# frozen_string_literal: true

module CaptiveStackDetector
  Services = Data.define(:database, :queue)
  Worker   = Data.define(:command)
  Runtime  = Data.define(:ruby, :node)
  Result   = Data.define(:type, :subtype, :services, :worker, :runtime, :env_vars)

  UnsupportedStack = Class.new(StandardError)
end
