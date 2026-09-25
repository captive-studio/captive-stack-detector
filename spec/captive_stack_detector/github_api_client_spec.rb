# frozen_string_literal: true

require "spec_helper"
require "base64"
require "json"
require "captive_stack_detector/github_api_client"

RSpec.describe CaptiveStackDetector::GithubApiClient do
  let(:token) { "ghp_test" }
  let(:repo)  { "captive-studio/my-app" }
  let(:client) { described_class.new(token, repo) }

  it "retourne le contenu d'un fichier depuis l'API GitHub" do
    stub_request(:get, "https://api.github.com/repos/#{repo}/contents/Gemfile")
      .with(headers: { "Authorization" => "Bearer #{token}" })
      .to_return(
        status: 200,
        body:   JSON.generate({ "content" => Base64.encode64("gem 'rails'") }),
        headers: { "Content-Type" => "application/json" },
      )
    expect(client.fetch("Gemfile")).to eq("gem 'rails'")
  end

  it "liste récursivement les fichiers d'un dossier via l'API Trees" do
    stub_request(:get, "https://api.github.com/repos/#{repo}/git/trees/HEAD?recursive=1")
      .to_return(
        status: 200,
        body:   JSON.generate({ "tree" => [
          { "path" => "app/jobs", "type" => "tree" },
          { "path" => "app/jobs/application_job.rb", "type" => "blob" },
          { "path" => "app/jobs/billing/invoice_job.rb", "type" => "blob" },
          { "path" => "app/models/user.rb", "type" => "blob" },
        ] }),
      )
    expect(client.list("app/jobs")).to eq([ "app/jobs/application_job.rb", "app/jobs/billing/invoice_job.rb" ])
  end

  it "retourne une liste vide si la réponse de l'API Trees est invalide" do
    stub_request(:get, "https://api.github.com/repos/#{repo}/git/trees/HEAD?recursive=1").to_return(status: 200, body: "oops")
    expect(client.list("app/jobs")).to eq([])
  end

  it "retourne une liste vide si l'API Trees échoue" do
    stub_request(:get, "https://api.github.com/repos/#{repo}/git/trees/HEAD?recursive=1").to_return(status: 404)
    expect(client.list("app/jobs")).to eq([])
  end
end
