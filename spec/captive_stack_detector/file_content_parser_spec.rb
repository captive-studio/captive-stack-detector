# frozen_string_literal: true

require "spec_helper"
require "captive_stack_detector/file_content_parser"

RSpec.describe CaptiveStackDetector::FileContentParser do
  let(:reader) { double("reader") }

  before(:each) do
    allow(reader).to receive(:read).and_return(nil)
  end

  describe "#node_version" do
    it "retourne le major depuis .nvmrc" do
      allow(reader).to receive(:read).with(".nvmrc").and_return("v22.3.1\n")
      expect(described_class.new(reader).node_version).to eq("22")
    end

    it "retourne le major depuis .tool-versions" do
      allow(reader).to receive(:read).with(".tool-versions").and_return("nodejs 20.11.0\n")
      expect(described_class.new(reader).node_version).to eq("20")
    end

    it "retourne le major depuis package.json engines.node quand .nvmrc et .tool-versions absents" do
      allow(reader).to receive(:read).with("package.json").and_return('{"engines":{"node":">=18.0.0"}}')
      expect(described_class.new(reader).node_version).to eq("18")
    end

    it "retourne nil si aucune source de version node" do
      expect(described_class.new(reader).node_version).to be_nil
    end
  end
end
