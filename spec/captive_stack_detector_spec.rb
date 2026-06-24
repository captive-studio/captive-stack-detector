# frozen_string_literal: true

require "spec_helper"
require "captive_stack_detector"

RSpec.describe CaptiveStackDetector do
  describe ".detect" do
    it "retourne type rails si Gemfile contient gem rails" do
      result = described_class.detect(gemfile: "gem 'rails'")
      expect(result.type).to eq("rails")
    end

    it "lève UnsupportedStack si Gemfile sans gem rails" do
      expect { described_class.detect(gemfile: "gem 'sinatra'") }
        .to raise_error(CaptiveStackDetector::UnsupportedStack)
    end

    it "lève UnsupportedStack si package.json sans script start" do
      expect { described_class.detect(package_json: '{"dependencies":{"express":"^4.0"}}') }
        .to raise_error(CaptiveStackDetector::UnsupportedStack)
    end

    it "retourne type node si package.json présent sans expo" do
      result = described_class.detect(package_json: '{"scripts":{"start":"node index.js"},"dependencies":{"express":"^4.0"}}')
      expect(result.type).to eq("node")
    end

    it "retourne type expo si package.json contient expo" do
      result = described_class.detect(package_json: '{"dependencies":{"expo":"~52.0"}}')
      expect(result.type).to eq("expo")
    end

    it "lève UnsupportedStack si ni Gemfile ni package.json" do
      expect { described_class.detect }
        .to raise_error(CaptiveStackDetector::UnsupportedStack)
    end

    it "retourne subtype api si Gemfile rails sans gems d'assets" do
      result = described_class.detect(gemfile: "gem 'rails'")
      expect(result.subtype).to eq("api")
    end

    it "retourne subtype app si Gemfile rails avec sprockets" do
      result = described_class.detect(gemfile: "gem 'rails'\ngem 'sprockets'")
      expect(result.subtype).to eq("app")
    end

    it "retourne subtype app si Gemfile rails avec propshaft" do
      result = described_class.detect(gemfile: "gem 'rails'\ngem 'propshaft'")
      expect(result.subtype).to eq("app")
    end

    it "retourne with_postgres true si Gemfile contient pg" do
      result = described_class.detect(gemfile: "gem 'rails'\ngem 'pg'")
      expect(result.with_postgres).to be(true)
    end

    it "retourne with_postgres false si Gemfile sans pg" do
      result = described_class.detect(gemfile: "gem 'rails'")
      expect(result.with_postgres).to be(false)
    end

    it "retourne with_redis true si Gemfile contient redis" do
      result = described_class.detect(gemfile: "gem 'rails'\ngem 'redis'")
      expect(result.with_redis).to be(true)
    end

    it "retourne worker_command bundle exec sidekiq si Gemfile contient sidekiq" do
      result = described_class.detect(gemfile: "gem 'rails'\ngem 'sidekiq'")
      expect(result.worker_command).to eq("bundle exec sidekiq")
    end

    it "retourne worker_command nil si Gemfile sans worker connu" do
      result = described_class.detect(gemfile: "gem 'rails'")
      expect(result.worker_command).to be_nil
    end
  end
end
