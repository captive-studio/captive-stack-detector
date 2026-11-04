# frozen_string_literal: true

require "spec_helper"
require "captive_stack_detector/types"

RSpec.describe CaptiveStackDetector do
  describe "Services" do
    it "est un Data avec database, queue et backend" do
      services = described_class::Services.new(database: "postgres", queue: "redis", backend: "supabase")
      expect(services.database).to eq("postgres")
      expect(services.queue).to eq("redis")
      expect(services.backend).to eq("supabase")
    end
  end

  describe "Result" do
    it "expose system_packages" do
      result = described_class::Result.new(
        type: "rails", subtype: "app",
        services: nil, worker: nil, runtime: nil, env_vars: {},
        system_packages: %w[libvips42]
      )
      expect(result.system_packages).to eq(%w[libvips42])
    end

    # captive-admin fusionne env_vars (merge) au provisionnement : un Array le faisait planter
    # sur un site statique (0.9.0).
    it "refuse des env_vars qui ne sont pas un Hash" do
      expect do
        described_class::Result.new(type: "node", subtype: nil, services: nil, worker: nil, runtime: nil,
                                    env_vars: [], system_packages: [])
      end.to raise_error(ArgumentError, /env_vars/)
    end
  end
end
