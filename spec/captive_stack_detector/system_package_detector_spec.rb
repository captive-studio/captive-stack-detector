# frozen_string_literal: true

require "spec_helper"
require "captive_stack_detector/system_package_detector"

RSpec.describe CaptiveStackDetector::SystemPackageDetector do
  subject(:detector) { described_class.new(gemfile:, aptfile: nil) }

  context "avec gem ruby-vips" do
    let(:gemfile) { "gem 'ruby-vips'" }

    it "retourne libvips42 et libvips-dev" do
      expect(detector.packages).to eq(%w[libvips42 libvips-dev])
    end
  end

  context "sans gem connue" do
    let(:gemfile) { "gem 'rails'" }

    it "retourne un tableau vide" do
      expect(detector.packages).to eq([])
    end
  end

  context "avec un Aptfile" do
    subject(:detector) { described_class.new(gemfile:, aptfile: "wkhtmltopdf\nlibsqlite3-dev\n") }

    let(:gemfile) { "gem 'rails'" }


    it "inclut les paquets déclarés dans l'Aptfile" do
      expect(detector.packages).to eq(%w[wkhtmltopdf libsqlite3-dev])
    end
  end

  context "avec gem sqlite3" do
    let(:gemfile) { "gem 'sqlite3'" }

    it "retourne libsqlite3-dev" do
      expect(detector.packages).to eq(%w[libsqlite3-dev])
    end
  end

  context "avec gem wkhtmltopdf" do
    let(:gemfile) { "gem 'wkhtmltopdf-binary'" }

    it "retourne wkhtmltopdf" do
      expect(detector.packages).to eq(%w[wkhtmltopdf])
    end
  end

  context "avec gem mini_magick" do
    let(:gemfile) { "gem 'mini_magick'" }

    it "retourne imagemagick" do
      expect(detector.packages).to eq(%w[imagemagick])
    end
  end

  context "avec gem ruby-vips et Aptfile contenant libvips42" do
    subject(:detector) { described_class.new(gemfile: "gem 'ruby-vips'", aptfile: "libvips42\n") }

    it "ne retourne pas de doublons" do
      expect(detector.packages).to eq(%w[libvips42 libvips-dev])
    end
  end

  context "avec un Aptfile contenant des commentaires" do
    subject(:detector) { described_class.new(gemfile:, aptfile: "# dépendance image\nwkhtmltopdf\n") }

    let(:gemfile) { "gem 'rails'" }


    it "ignore les lignes commentées" do
      expect(detector.packages).to eq(%w[wkhtmltopdf])
    end
  end
end
