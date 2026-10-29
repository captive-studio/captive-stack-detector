# frozen_string_literal: true

require "spec_helper"
require "json"
require "captive_stack_detector/package_json_analyzer"

RSpec.describe CaptiveStackDetector::PackageJsonAnalyzer do
  it "retourne type expo si dépendance expo présente" do
    pkg = JSON.generate({ "dependencies" => { "expo" => "~50.0.0" } })
    expect(described_class.new(pkg).type).to eq("expo")
  end

  it "retourne type node si script start présent" do
    pkg = JSON.generate({ "scripts" => { "start" => "node server.js" } })
    expect(described_class.new(pkg).type).to eq("node")
  end

  it "retourne type node si seul un script build est présent (SPA)" do
    pkg = JSON.generate({ "scripts" => { "build" => "vite build", "dev" => "vite" } })
    expect(described_class.new(pkg).type).to eq("node")
  end

  it "retourne nil si ni expo ni script start" do
    pkg = JSON.generate({ "name" => "my-app" })
    expect(described_class.new(pkg).type).to be_nil
  end

  it "détecte expo depuis devDependencies" do
    pkg = JSON.generate({ "devDependencies" => { "expo" => "~50.0.0" } })
    expect(described_class.new(pkg).type).to eq("expo")
  end

  it "retourne database postgres si pg présent dans dependencies" do
    pkg = JSON.generate({ "dependencies" => { "pg" => "^8.0", "express" => "^4.0" } })
    expect(described_class.new(pkg).database).to eq("postgres")
  end

  it "retourne database postgres si le client postgres (postgres.js) est présent" do
    pkg = JSON.generate({ "dependencies" => { "postgres" => "^3.4.9", "next" => "16.4.0" } })
    expect(described_class.new(pkg).database).to eq("postgres")
  end

  it "retourne database nil si pas de pg" do
    pkg = JSON.generate({ "dependencies" => { "express" => "^4.0" } })
    expect(described_class.new(pkg).database).to be_nil
  end

  it "retourne queue redis si ioredis présent dans dependencies" do
    pkg = JSON.generate({ "dependencies" => { "ioredis" => "^5.0" } })
    expect(described_class.new(pkg).queue).to eq("redis")
  end

  it "retourne queue nil si pas de client redis" do
    pkg = JSON.generate({ "dependencies" => { "express" => "^4.0" } })
    expect(described_class.new(pkg).queue).to be_nil
  end

  it "retourne subtype server si un framework SSR (next) est présent" do
    pkg = JSON.generate({ "dependencies" => { "next" => "^14.0" }, "scripts" => { "start" => "next start" } })
    expect(described_class.new(pkg).subtype).to eq("server")
  end

  it "retourne subtype server pour nuxt" do
    pkg = JSON.generate({ "dependencies" => { "nuxt" => "^3.0" } })
    expect(described_class.new(pkg).subtype).to eq("server")
  end

  it "retourne subtype server pour @sveltejs/kit" do
    pkg = JSON.generate({ "devDependencies" => { "@sveltejs/kit" => "^2.0" } })
    expect(described_class.new(pkg).subtype).to eq("server")
  end

  it "retourne subtype server pour remix (paquets scopés @remix-run/*)" do
    pkg = JSON.generate({ "dependencies" => { "@remix-run/node" => "^2.0", "@remix-run/react" => "^2.0" } })
    expect(described_class.new(pkg).subtype).to eq("server")
  end

  it "retourne subtype server pour Astro avec son adaptateur Node" do
    pkg = JSON.generate({ "dependencies" => { "astro" => "^7.4.4", "@astrojs/node" => "^11.1.9" } })
    expect(described_class.new(pkg).subtype).to eq("server")
  end

  it "reconnaît aussi l'adaptateur Astro Node dans devDependencies" do
    pkg = JSON.generate({ "dependencies" => { "astro" => "^7.4.4" }, "devDependencies" => { "@astrojs/node" => "^11.1.9" } })
    expect(described_class.new(pkg).subtype).to eq("server")
  end

  it "garde Astro sans adaptateur Node en statique" do
    pkg = JSON.generate({ "dependencies" => { "astro" => "^7.4.4" }, "scripts" => { "build" => "astro build" } })
    expect(described_class.new(pkg).subtype).to be_nil
  end

  describe "#public_env_prefix" do
    def prefixe(deps) = described_class.new(JSON.generate({ "dependencies" => deps })).public_env_prefix

    it "donne le préfixe des variables exposées au navigateur, selon le bundler" do
      expect(prefixe("vite" => "7.0.0")).to eq("VITE_")
      expect(prefixe("next" => "15.0.0")).to eq("NEXT_PUBLIC_")
      expect(prefixe("expo" => "54.0.0")).to eq("EXPO_PUBLIC_")
    end

    # vite arrive souvent avec Vitest : ce n'est pas lui qui construit le front.
    it "préfère expo puis next à vite" do
      expect(prefixe("next" => "15.0.0", "vite" => "7.0.0")).to eq("NEXT_PUBLIC_")
      expect(prefixe("expo" => "54.0.0", "next" => "15.0.0")).to eq("EXPO_PUBLIC_")
    end

    it "n'en donne aucun sans bundler front" do
      expect(prefixe("express" => "5.0.0")).to be_nil
    end
  end
end
