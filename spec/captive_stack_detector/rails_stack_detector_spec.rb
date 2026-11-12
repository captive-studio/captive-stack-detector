# frozen_string_literal: true

require "spec_helper"
require "captive_stack_detector"
require "captive_stack_detector/rails_stack_detector"

RSpec.describe CaptiveStackDetector::RailsStackDetector do
  let(:reader) do
    double("reader",
      read:        nil,
      ruby_version: nil,
      node_version: nil,
      env_vars:    {},
    )
  end

  it "retourne un Result type rails depuis un Gemfile avec gem rails" do
    analyzer = CaptiveStackDetector::GemfileAnalyzer.new("gem 'rails'")
    result = described_class.new(reader, analyzer).detect
    expect(result.type).to eq("rails")
  end

  it "détecte les paquets système des gems transitifs du Gemfile.lock" do
    allow(reader).to receive(:read).with("Gemfile.lock").and_return("GEM\n  specs:\n    ethon (0.18.0)\n")
    analyzer = CaptiveStackDetector::GemfileAnalyzer.new("gem 'rails'")
    result = described_class.new(reader, analyzer).detect
    expect(result.system_packages).to eq(%w[libcurl4t64])
  end

  it "reprend la version de Node déclarée par l'app" do
    allow(reader).to receive(:node_version).and_return("26")
    analyzer = CaptiveStackDetector::GemfileAnalyzer.new("gem 'rails'")
    result = described_class.new(reader, analyzer).detect
    expect(result.runtime.node).to eq("26")
  end
end
