# frozen_string_literal: true

require "spec_helper"
require "captive_stack_detector/gem_package_map"

RSpec.describe CaptiveStackDetector::GemPackageMap do
  it "retourne les paires gem → paquets pour les gems présents dans le Gemfile" do
    expect(described_class.matches("gem 'ruby-vips'")).to eq({ "ruby-vips" => %w[libvips42 libvips-dev] })
  end

  it "ignore les gems absents" do
    expect(described_class.matches("gem 'rails'")).to eq({})
  end

  it "reconnaît un gem déclaré en guillemets doubles" do
    expect(described_class.matches('gem "sqlite3"')).to eq({ "sqlite3" => %w[libsqlite3-dev] })
  end
end
