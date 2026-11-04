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

    expect(detect.services.backend).to eq("supabase")
  end

  it "refuse toujours un dépôt sans manifeste ni index.html" do
    write("README.md")

    expect { detect }.to raise_error(CaptiveStackDetector::UnsupportedStack) { |e| expect(e.reason).to eq(:no_manifest) }
  end

  it "laisse le package.json décider quand il existe" do
    write("index.html")
    write("package.json", { "dependencies" => { "lodash" => "4" } }.to_json)

    expect { detect }.to raise_error(CaptiveStackDetector::UnsupportedStack) { |e| expect(e.reason).to eq(:no_node_entry) }
  end
end
