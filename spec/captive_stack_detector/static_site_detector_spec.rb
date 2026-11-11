# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "fileutils"
require "json"
require "captive_stack_detector"

RSpec.describe CaptiveStackDetector::StaticSiteDetector do
  around do |example|
    Dir.mktmpdir do |dir|
      @dir = dir
      example.run
    end
  end

  def write(path, content = "x")
    FileUtils.mkdir_p(File.dirname(File.join(@dir, path)))
    File.write(File.join(@dir, path), content)
  end

  def detect = CaptiveStackDetector.detect(local_path: @dir)

  it "classe node, sans subtype ni service, un dépôt sans manifeste qui a public/index.html" do
    write("public/index.html")

    # env_vars est un Hash pour toutes les stacks : captive-admin le fusionne (merge) au provisionnement.
    expect(detect).to have_attributes(type: "node", subtype: nil, worker: nil, env_vars: {}, system_packages: [])
    expect(detect.services).to have_attributes(database: nil, queue: nil, backend: nil)
  end

  it "accepte un index.html à la racine, et voit Supabase à son config.toml" do
    write("index.html")
    write("supabase/config.toml")

    # Supabase repose sur Postgres, comme pour une stack Node : sans la base, le provisionnement
    # écrit un Supabase sans cluster et services check le refuse.
    expect(detect.services).to have_attributes(backend: "supabase", database: "postgres")
  end

  it "refuse toujours un dépôt sans manifeste ni index.html" do
    write("README.md")

    expect { detect }.to raise_error(CaptiveStackDetector::UnsupportedStack) { |e| expect(e.reason).to eq(:no_manifest) }
  end

  it "sert en statique un index.html dont le package.json n'est que de l'outillage" do
    write("index.html")
    write("supabase/config.toml")
    write("package.json", { "devDependencies" => { "supabase" => "2" } }.to_json)

    expect(detect).to have_attributes(type: "node", subtype: nil)
    expect(detect.services).to have_attributes(backend: "supabase", database: "postgres")
  end

  it "laisse un package.json avec un script build décider, même avec un index.html" do
    write("index.html")
    write("package.json", { "scripts" => { "build" => "vite build" }, "dependencies" => { "vite" => "5" } }.to_json)

    expect(detect).to have_attributes(type: "node", public_env_prefix: "VITE_")
  end

  it "refuse un package.json sans point d'entrée quand aucun index.html ne le rattrape" do
    write("package.json", { "dependencies" => { "lodash" => "4" } }.to_json)

    expect { detect }.to raise_error(CaptiveStackDetector::UnsupportedStack) { |e| expect(e.reason).to eq(:no_node_entry) }
  end
end
