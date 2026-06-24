# frozen_string_literal: true

require "spec_helper"
require "captive_stack_detector/gemfile_analyzer"

RSpec.describe CaptiveStackDetector::GemfileAnalyzer do
  subject(:analyzer) { described_class.new("gem 'rails'") }

  it "détecte rails?" do
    expect(analyzer.rails?).to be(true)
  end
end
