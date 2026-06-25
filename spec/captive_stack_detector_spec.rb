# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "fileutils"
require "json"
require "base64"
require "captive_stack_detector"

RSpec.describe CaptiveStackDetector do
  describe ".detect" do
    describe "local_path:" do
      it "retourne type rails depuis un Gemfile avec gem rails" do
        Dir.mktmpdir do |path|
          File.write(File.join(path, "Gemfile"), "gem 'rails'")
          result = described_class.detect(local_path: path)
          expect(result.type).to eq("rails")
        end
      end

      it "retourne subtype app si Gemfile contient sprockets-rails" do
        Dir.mktmpdir do |path|
          File.write(File.join(path, "Gemfile"), "gem 'rails'\ngem 'sprockets-rails'")
          result = described_class.detect(local_path: path)
          expect(result.subtype).to eq("app")
        end
      end

      it "retourne services.database postgres si Gemfile contient gem pg" do
        Dir.mktmpdir do |path|
          File.write(File.join(path, "Gemfile"), "gem 'rails'\ngem 'pg'")
          result = described_class.detect(local_path: path)
          expect(result.services.database).to eq("postgres")
        end
      end

      it "retourne services.database nil si Gemfile sans pg" do
        Dir.mktmpdir do |path|
          File.write(File.join(path, "Gemfile"), "gem 'rails'")
          result = described_class.detect(local_path: path)
          expect(result.services.database).to be_nil
        end
      end

      it "retourne services.queue redis si Gemfile contient gem sidekiq" do
        Dir.mktmpdir do |path|
          File.write(File.join(path, "Gemfile"), "gem 'rails'\ngem 'sidekiq'")
          result = described_class.detect(local_path: path)
          expect(result.services.queue).to eq("redis")
        end
      end

      it "retourne services.queue nil si Gemfile sans redis/sidekiq" do
        Dir.mktmpdir do |path|
          File.write(File.join(path, "Gemfile"), "gem 'rails'")
          result = described_class.detect(local_path: path)
          expect(result.services.queue).to be_nil
        end
      end

      it "retourne worker.command depuis le Procfile si ligne worker: présente" do
        Dir.mktmpdir do |path|
          File.write(File.join(path, "Gemfile"), "gem 'rails'")
          File.write(File.join(path, "Procfile"), "web: bundle exec puma\nworker: bundle exec sidekiq -q default\n")
          result = described_class.detect(local_path: path)
          expect(result.worker.command).to eq("bundle exec sidekiq -q default")
        end
      end

      it "retourne worker.command bundle exec sidekiq si gem sidekiq sans Procfile" do
        Dir.mktmpdir do |path|
          File.write(File.join(path, "Gemfile"), "gem 'rails'\ngem 'sidekiq'")
          result = described_class.detect(local_path: path)
          expect(result.worker.command).to eq("bundle exec sidekiq")
        end
      end

      it "retourne worker nil si pas de sidekiq et pas de Procfile worker" do
        Dir.mktmpdir do |path|
          File.write(File.join(path, "Gemfile"), "gem 'rails'")
          result = described_class.detect(local_path: path)
          expect(result.worker).to be_nil
        end
      end

      it "retourne runtime.ruby depuis .tool-versions" do
        Dir.mktmpdir do |path|
          File.write(File.join(path, "Gemfile"), "gem 'rails'")
          File.write(File.join(path, ".tool-versions"), "ruby 3.3.0\nnodejs 20.11.0\n")
          result = described_class.detect(local_path: path)
          expect(result.runtime.ruby).to eq("3.3.0")
        end
      end

      it "retourne runtime.ruby nil si pas de .tool-versions" do
        Dir.mktmpdir do |path|
          File.write(File.join(path, "Gemfile"), "gem 'rails'")
          result = described_class.detect(local_path: path)
          expect(result.runtime.ruby).to be_nil
        end
      end

      it "lève UnsupportedStack si ni Gemfile ni package.json" do
        Dir.mktmpdir do |path|
          expect { described_class.detect(local_path: path) }.to raise_error(CaptiveStackDetector::UnsupportedStack)
        end
      end

      it "lève UnsupportedStack si Gemfile sans gem rails" do
        Dir.mktmpdir do |path|
          File.write(File.join(path, "Gemfile"), "gem 'sinatra'")
          expect { described_class.detect(local_path: path) }.to raise_error(CaptiveStackDetector::UnsupportedStack)
        end
      end

      it "retourne type node si package.json avec script start" do
        Dir.mktmpdir do |path|
          File.write(File.join(path, "package.json"), JSON.generate({ "scripts" => { "start" => "node server.js" } }))
          result = described_class.detect(local_path: path)
          expect(result.type).to eq("node")
        end
      end

      it "retourne type expo si package.json avec dépendance expo" do
        Dir.mktmpdir do |path|
          File.write(File.join(path, "package.json"), JSON.generate({ "dependencies" => { "expo" => "~50.0.0" } }))
          result = described_class.detect(local_path: path)
          expect(result.type).to eq("expo")
        end
      end

      it "lève UnsupportedStack si package.json sans script start ni expo" do
        Dir.mktmpdir do |path|
          File.write(File.join(path, "package.json"), JSON.generate({ "name" => "my-app" }))
          expect { described_class.detect(local_path: path) }.to raise_error(CaptiveStackDetector::UnsupportedStack)
        end
      end

      it "lève ArgumentError si ni local_path ni github_token" do
        expect { described_class.detect }.to raise_error(ArgumentError)
      end

      it "retourne subtype api si Gemfile rails sans gems d'assets" do
        Dir.mktmpdir do |path|
          File.write(File.join(path, "Gemfile"), "gem 'rails'\ngem 'pg'")
          result = described_class.detect(local_path: path)
          expect(result.subtype).to eq("api")
        end
      end

      it "retourne runtime.node depuis .nvmrc" do
        Dir.mktmpdir do |path|
          File.write(File.join(path, "package.json"), JSON.generate({ "scripts" => { "start" => "node server.js" } }))
          File.write(File.join(path, ".nvmrc"), "v20.11.0\n")
          result = described_class.detect(local_path: path)
          expect(result.runtime.node).to eq("20")
        end
      end

      it "retourne runtime.node depuis .tool-versions ligne nodejs" do
        Dir.mktmpdir do |path|
          File.write(File.join(path, "package.json"), JSON.generate({ "scripts" => { "start" => "node server.js" } }))
          File.write(File.join(path, ".tool-versions"), "nodejs 18.20.0\n")
          result = described_class.detect(local_path: path)
          expect(result.runtime.node).to eq("18")
        end
      end

      it "retourne runtime.node nil si pas de .nvmrc ni nodejs dans .tool-versions" do
        Dir.mktmpdir do |path|
          File.write(File.join(path, "package.json"), JSON.generate({ "scripts" => { "start" => "node server.js" } }))
          result = described_class.detect(local_path: path)
          expect(result.runtime.node).to be_nil
        end
      end

      it "retourne env_vars depuis config/storage.yml" do
        Dir.mktmpdir do |path|
          File.write(File.join(path, "Gemfile"), "gem 'rails'")
          FileUtils.mkdir_p(File.join(path, "config"))
          File.write(File.join(path, "config/storage.yml"), <<~YAML)
            amazon:
              service: S3
              access_key_id: <%= ENV.fetch("AWS_ACCESS_KEY_ID") %>
              secret_access_key: <%= ENV.fetch("AWS_SECRET_ACCESS_KEY") %>
          YAML
          result = described_class.detect(local_path: path)
          expect(result.env_vars).to include("AWS_ACCESS_KEY_ID", "AWS_SECRET_ACCESS_KEY")
        end
      end
    end

    describe "github_token: + repo:" do
      let(:token)   { "ghp_test_token" }
      let(:repo)    { "captive-studio/my-app" }
      let(:api_url) { "https://api.github.com/repos/#{repo}/contents" }

      def stub_github(path, content)
        stub_request(:get, "#{api_url}/#{path}")
          .with(headers: { "Authorization" => "Bearer #{token}" })
          .to_return(
            status: 200,
            body:   JSON.generate({ "content" => Base64.encode64(content) }),
            headers: { "Content-Type" => "application/json" },
          )
      end

      def stub_github_404(path)
        stub_request(:get, "#{api_url}/#{path}")
          .to_return(status: 404, body: '{"message":"Not Found"}')
      end

      before(:each) do
        stub_github_404("Gemfile")
        stub_github_404("package.json")
        stub_github_404(".tool-versions")
        stub_github_404(".ruby-version")
        stub_github_404(".nvmrc")
        stub_github_404("Procfile")
        stub_github_404("config/storage.yml")
      end

      it "retourne type rails depuis GitHub via Gemfile" do
        stub_github("Gemfile", "gem 'rails'")
        result = described_class.detect(github_token: token, repo: repo)
        expect(result.type).to eq("rails")
      end

      it "retourne type node depuis GitHub via package.json" do
        stub_github("package.json", JSON.generate({ "scripts" => { "start" => "node server.js" } }))
        result = described_class.detect(github_token: token, repo: repo)
        expect(result.type).to eq("node")
      end

      it "retourne nil si appel GitHub échoue pour un fichier optionnel" do
        stub_github("Gemfile", "gem 'rails'")
        result = described_class.detect(github_token: token, repo: repo)
        expect(result.runtime.ruby).to be_nil
      end

      it "lève UnsupportedStack si ni Gemfile ni package.json sur GitHub" do
        expect { described_class.detect(github_token: token, repo: repo) }
          .to raise_error(CaptiveStackDetector::UnsupportedStack)
      end

      it "retourne runtime.ruby depuis .tool-versions GitHub" do
        stub_github("Gemfile", "gem 'rails'")
        stub_github(".tool-versions", "ruby 3.2.1\n")
        result = described_class.detect(github_token: token, repo: repo)
        expect(result.runtime.ruby).to eq("3.2.1")
      end

      it "retourne runtime.ruby depuis .ruby-version GitHub" do
        stub_github("Gemfile", "gem 'rails'")
        stub_github(".ruby-version", "3.3.0\n")
        result = described_class.detect(github_token: token, repo: repo)
        expect(result.runtime.ruby).to eq("3.3.0")
      end

      it "retourne runtime.ruby depuis ruby dans le Gemfile GitHub" do
        stub_github("Gemfile", "ruby \"3.3.4\"\ngem 'rails'")
        result = described_class.detect(github_token: token, repo: repo)
        expect(result.runtime.ruby).to eq("3.3.4")
      end

      it "retourne runtime.node depuis .nvmrc GitHub" do
        stub_github("package.json", JSON.generate({ "scripts" => { "start" => "node server.js" } }))
        stub_github(".nvmrc", "v20.0.0\n")
        result = described_class.detect(github_token: token, repo: repo)
        expect(result.runtime.node).to eq("20")
      end

      it "retourne runtime.node depuis .tool-versions nodejs GitHub" do
        stub_github("package.json", JSON.generate({ "scripts" => { "start" => "node server.js" } }))
        stub_github(".tool-versions", "nodejs 18.20.0\n")
        result = described_class.detect(github_token: token, repo: repo)
        expect(result.runtime.node).to eq("18")
      end

      it "gère l'erreur réseau GitHub en retournant nil pour le fichier" do
        stub_request(:get, "#{api_url}/Gemfile")
          .to_raise(SocketError.new("getaddrinfo: nodename nor servname provided"))
        stub_github("package.json", JSON.generate({ "scripts" => { "start" => "node server.js" } }))
        result = described_class.detect(github_token: token, repo: repo)
        expect(result.type).to eq("node")
      end

      it "retourne env_vars depuis storage.yml avec syntaxe ENV[\"KEY\"]" do
        stub_github("Gemfile", "gem 'rails'")
        stub_github("config/storage.yml", 'bucket: <%= ENV["BUCKET_NAME"] %>')
        result = described_class.detect(github_token: token, repo: repo)
        expect(result.env_vars).to include("BUCKET_NAME")
      end
    end
  end
end
