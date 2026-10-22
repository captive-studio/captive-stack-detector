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

  it "reconnaît un gem présent seulement en dépendance transitive dans le Gemfile.lock" do
    lockfile = "GEM\n  specs:\n    ethon (0.18.0)\n      ffi (>= 1.15.0)\n    typhoeus (1.6.0)\n      ethon (>= 0.18.0)\n"
    expect(described_class.matches("gem 'sib-api-v3-sdk'", lockfile)).to eq({ "ethon" => %w[libcurl4t64] })
  end

  it "ignore un gem cité seulement comme contrainte de version dans le Gemfile.lock" do
    lockfile = "GEM\n  specs:\n    typhoeus (1.6.0)\n      ethon (>= 0.18.0)\n"
    expect(described_class.matches("gem 'rails'", lockfile)).to eq({})
  end
end
