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
end
