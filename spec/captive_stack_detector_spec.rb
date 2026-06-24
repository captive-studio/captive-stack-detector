# frozen_string_literal: true

require "spec_helper"
require "captive_stack_detector"

RSpec.describe CaptiveStackDetector do
  describe ".detect" do
    it "retourne type rails si Gemfile contient gem rails" do
      result = described_class.detect(gemfile: "gem 'rails'")
      expect(result.type).to eq("rails")
    end

    it "lève UnsupportedStack si Gemfile sans gem rails" do
      expect { described_class.detect(gemfile: "gem 'sinatra'") }
        .to raise_error(CaptiveStackDetector::UnsupportedStack)
    end

    it "retourne type node si package.json présent sans expo" do
      result = described_class.detect(package_json: '{"dependencies":{"express":"^4.0"}}')
      expect(result.type).to eq("node")
    end

    it "retourne type expo si package.json contient expo" do
      result = described_class.detect(package_json: '{"dependencies":{"expo":"~52.0"}}')
      expect(result.type).to eq("expo")
    end

    it "lève UnsupportedStack si ni Gemfile ni package.json" do
      expect { described_class.detect }
        .to raise_error(CaptiveStackDetector::UnsupportedStack)
    end
  end
end
