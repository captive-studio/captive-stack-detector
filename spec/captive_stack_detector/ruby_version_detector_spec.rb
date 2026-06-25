# frozen_string_literal: true

require "spec_helper"
require "captive_stack_detector/ruby_version_detector"

RSpec.describe CaptiveStackDetector::RubyVersionDetector do
  let(:reader) { double("reader") }

  before(:each) do
    allow(reader).to receive(:read).and_return(nil)
  end

  it "retourne la version depuis .tool-versions" do
    allow(reader).to receive(:read).with(".tool-versions").and_return("ruby 3.3.0\nnodejs 20.11.0\n")
    expect(described_class.new(reader).detect).to eq("3.3.0")
  end

  it "retourne la version depuis .ruby-version" do
    allow(reader).to receive(:read).with(".ruby-version").and_return("3.2.1\n")
    expect(described_class.new(reader).detect).to eq("3.2.1")
  end

  it "stripe le préfixe ruby- de .ruby-version" do
    allow(reader).to receive(:read).with(".ruby-version").and_return("ruby-3.2.1\n")
    expect(described_class.new(reader).detect).to eq("3.2.1")
  end

  it "retourne la version depuis le Gemfile" do
    allow(reader).to receive(:read).with("Gemfile").and_return("source 'https://rubygems.org'\nruby \"3.3.4\"\ngem 'rails'\n")
    expect(described_class.new(reader).detect).to eq("3.3.4")
  end

  it "retourne nil si le Gemfile contient une contrainte floue" do
    allow(reader).to receive(:read).with("Gemfile").and_return("ruby \">= 3.0\"\n")
    expect(described_class.new(reader).detect).to be_nil
  end

  it "retourne nil si aucune source de version ruby" do
    expect(described_class.new(reader).detect).to be_nil
  end
end
