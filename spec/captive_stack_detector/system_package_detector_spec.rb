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

  context "avec gem wkhtmltopdf-binary" do
    let(:gemfile) { "gem 'wkhtmltopdf-binary'" }

    it "ne retourne aucun paquet — wkhtmltopdf n'existe plus dans Debian Trixie et le projet upstream est abandonné" do
      expect(detector.packages).to eq([])
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

  context "avec un Aptfile contenant un commentaire en fin de ligne" do
    subject(:detector) { described_class.new(gemfile:, aptfile: "wkhtmltopdf # ne fonctionne plus avec captive-platform\nlibjemalloc2\n") }

    let(:gemfile) { "gem 'rails'" }

    it "tronque le commentaire et ne garde que le nom du paquet" do
      expect(detector.packages).to eq(%w[wkhtmltopdf libjemalloc2])
    end
  end

  context "logs pendant la recherche" do
    let(:gemfile) { "gem 'ruby-vips'" }
    let(:detector) { described_class.new(gemfile:, aptfile: "libsqlite3-dev\n") }

    it "logue chaque gem détectée avec ses paquets sur stderr" do
      expect { detector.packages }.to output(/gem 'ruby-vips' détecté → libvips42, libvips-dev/).to_stderr
    end

    it "logue chaque paquet trouvé dans l'Aptfile sur stderr" do
      expect { detector.packages }.to output(/Aptfile → paquet 'libsqlite3-dev'/).to_stderr
    end

    it "logue le résumé des paquets détectés sur stderr" do
      expect { detector.packages }.to output(/paquets système détectés : libvips42, libvips-dev, libsqlite3-dev/).to_stderr
    end
  end

  context "logs quand aucun paquet n'est trouvé" do
    subject(:detector) { described_class.new(gemfile: "gem 'rails'", aptfile: nil) }

    it "logue qu'aucun paquet n'a été détecté" do
      expect { detector.packages }.to output(/paquets système détectés : aucun/).to_stderr
    end
  end

  context "avec une gem mappée vers aucun paquet" do
    let(:gemfile) { "gem 'wkhtmltopdf-binary'" }
    let(:detector) { described_class.new(gemfile:, aptfile: nil) }

    it "logue que la gem ne nécessite aucun paquet" do
      expect { detector.packages }.to output(/gem 'wkhtmltopdf-binary' détecté → aucun paquet/).to_stderr
    end
  end
end
