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
end
