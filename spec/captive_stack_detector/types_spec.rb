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
end
