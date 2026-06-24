# frozen_string_literal: true

require "spec_helper"
require "captive/stack/detector"

RSpec.describe CaptiveStackDetector do
  it "est accessible via require captive/stack/detector" do
    expect(described_class).to be(CaptiveStackDetector)
  end
end
