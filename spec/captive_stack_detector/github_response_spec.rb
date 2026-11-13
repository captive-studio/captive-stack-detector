# frozen_string_literal: true

require "spec_helper"
require "captive_stack_detector/github_response"

RSpec.describe CaptiveStackDetector::GithubResponse do
  def reponse(code, headers = {})
    classe = Net::HTTPResponse::CODE_TO_OBJ.fetch(code)
    classe.new("1.1", code, "").tap do |res|
      headers.each { |cle, valeur| res[cle] = valeur }
      res.instance_variable_set(:@body, "corps")
      res.instance_variable_set(:@read, true)
    end
  end

  def kind_of(code, headers = {})
    described_class.body(reponse(code, headers))
  rescue CaptiveStackDetector::SourceUnavailable => e
    [ e.kind, e.status ]
  end

  it "rend le corps d'un succès" do
    expect(described_class.body(reponse("200"))).to eq("corps")
  end

  it "rend nil pour un fichier absent ou un dépôt vide" do
    expect([ kind_of("404"), kind_of("409") ]).to eq([ nil, nil ])
  end

  it "nomme la cause d'un refus" do
    expect([ kind_of("401"), kind_of("403"), kind_of("429"), kind_of("502") ])
      .to eq([ [ :unauthorized, 401 ], [ :forbidden, 403 ], [ :rate_limited, 429 ], [ :server_error, 502 ] ])
  end

  it "reconnaît un quota épuisé derrière un 403" do
    expect(kind_of("403", "x-ratelimit-remaining" => "0")).to eq([ :rate_limited, 403 ])
  end
end
