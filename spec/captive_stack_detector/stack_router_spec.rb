# frozen_string_literal: true

require "spec_helper"
require "json"
require "captive_stack_detector"

RSpec.describe CaptiveStackDetector::StackRouter do
  def reader(files) = double("reader", read: nil, list: [], node_version: nil).tap { |r| files.each { |path, content| allow(r).to receive(:read).with(path).and_return(content) } }

  it "sert l'index.html quand le package.json n'est que de l'outillage" do
    result = described_class.new(reader("package.json" => "{}", "index.html" => "x")).detect

    expect(result).to have_attributes(type: "node", public_env_prefix: nil)
  end

  it "refuse un dépôt sans manifeste ni index.html" do
    expect { described_class.new(reader({})).detect }
      .to raise_error(CaptiveStackDetector::UnsupportedStack) { |e| expect(e.reason).to eq(:no_manifest) }
  end
end
