# frozen_string_literal: true

require "spec_helper"
require "captive_stack_detector/version"

RSpec.describe CaptiveStackDetector do
  describe "VERSION" do
    it "est une chaîne SemVer valide" do
      expect(described_class::VERSION).to match(/\A\d+\.\d+\.\d+\z/)
    end
  end
end
