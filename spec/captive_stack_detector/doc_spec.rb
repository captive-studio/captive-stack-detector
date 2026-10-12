# frozen_string_literal: true

require "spec_helper"
require "captive_stack_detector"

RSpec.describe "CaptiveStackDetector::DOC_PATH" do
  let(:doc) { File.read(CaptiveStackDetector::DOC_PATH, encoding: "UTF-8") }

  it "est livrée dans la gem" do
    spec = Gem::Specification.load(File.expand_path("../../captive-stack-detector.gemspec", __dir__))
    expect(spec.files).to include("docs/stacks.md")
  end

  it "explique chaque message de refus de stack" do
    expect(doc).to include(
      "Aucun Gemfile ni package.json à la racine du dépôt.",
      "Gemfile trouvé, mais sans la gem rails.",
      "package.json trouvé, mais sans dépendance expo ni script start ou build.",
    )
  end
end
