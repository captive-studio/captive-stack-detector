# frozen_string_literal: true

require "spec_helper"
require "captive_stack_detector/aptfile_parser"

RSpec.describe CaptiveStackDetector::AptfileParser do
  it "retourne les paquets déclarés, un par ligne" do
    expect(described_class.parse("libpq-dev\nimagemagick\n")).to eq(%w[libpq-dev imagemagick])
  end

  it "ignore les commentaires en fin de ligne et les lignes vides" do
    content = "libpq-dev # base\n\n  imagemagick\n# ligne entièrement commentée\n"
    expect(described_class.parse(content)).to eq(%w[libpq-dev imagemagick])
  end

  it "retourne un tableau vide pour un contenu vide" do
    expect(described_class.parse("")).to eq([])
  end
end
