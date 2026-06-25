# frozen_string_literal: true

require "spec_helper"
require "json"
require "captive_stack_detector"
require "captive_stack_detector/js_stack_detector"

RSpec.describe CaptiveStackDetector::JsStackDetector do
  let(:reader) { double("reader", node_version: nil) }

  it "retourne type node pour un package.json avec script start" do
    pkg = JSON.generate({ "scripts" => { "start" => "node server.js" } })
    result = described_class.new(reader, pkg).detect
    expect(result.type).to eq("node")
  end

  it "retourne type expo si dépendance expo présente" do
    pkg = JSON.generate({ "dependencies" => { "expo" => "~50.0.0" } })
    result = described_class.new(reader, pkg).detect
    expect(result.type).to eq("expo")
  end

  it "lève UnsupportedStack si pas de script start ni expo" do
    pkg = JSON.generate({ "name" => "my-app" })
    expect { described_class.new(reader, pkg).detect }.to raise_error(CaptiveStackDetector::UnsupportedStack)
  end

  it "retourne runtime.node depuis le reader" do
    allow(reader).to receive(:node_version).and_return("20")
    pkg = JSON.generate({ "scripts" => { "start" => "node server.js" } })
    result = described_class.new(reader, pkg).detect
    expect(result.runtime.node).to eq("20")
  end
end
