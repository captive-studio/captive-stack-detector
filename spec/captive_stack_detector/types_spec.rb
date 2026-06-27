# frozen_string_literal: true

require "spec_helper"
require "captive_stack_detector/types"

RSpec.describe CaptiveStackDetector do
  describe "Services" do
    it "est un Data avec database et queue" do
      services = described_class::Services.new(database: "postgres", queue: "redis")
      expect(services.database).to eq("postgres")
      expect(services.queue).to eq("redis")
    end
  end

  describe "Result" do
    it "expose system_packages" do
      result = described_class::Result.new(
        type: "rails", subtype: "app",
        services: nil, worker: nil, runtime: nil, env_vars: [],
        system_packages: %w[libvips42]
      )
      expect(result.system_packages).to eq(%w[libvips42])
    end
  end
end
