# frozen_string_literal: true

require "spec_helper"
require "captive_stack_detector"
require "captive_stack_detector/rails_stack_detector"

RSpec.describe CaptiveStackDetector::RailsStackDetector do
  let(:reader) do
    double("reader",
      read:        nil,
      ruby_version: nil,
      env_vars:    {},
    )
  end

  it "retourne un Result type rails depuis un Gemfile avec gem rails" do
    analyzer = CaptiveStackDetector::GemfileAnalyzer.new("gem 'rails'")
    result = described_class.new(reader, analyzer).detect
    expect(result.type).to eq("rails")
  end
end
