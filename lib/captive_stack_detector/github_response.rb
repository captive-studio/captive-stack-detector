# frozen_string_literal: true

require "net/http"
require_relative "types"

module CaptiveStackDetector
  # Ce que veut dire une réponse de l'API GitHub : un corps, une absence, ou un refus nommé.
  # Change avec la façon dont GitHub signale ses erreurs, pas avec ce que l'on y lit.
  module GithubResponse
    # 404 : fichier absent ; 409 : dépôt vide. Tout autre échec vient de GitHub, pas du dépôt.
    ABSENT = [ "404", "409" ].freeze
    REFUSALS = { "401" => :unauthorized, "429" => :rate_limited }.freeze

    def self.body(res)
      return res.body if res.is_a?(Net::HTTPSuccess)
      return nil if ABSENT.include?(res.code)

      raise SourceUnavailable.new(refusal_kind(res), status: res.code.to_i)
    end

    # GitHub signale un quota épuisé par un 403 ou un 429, avec x-ratelimit-remaining à 0.
    def self.refusal_kind(res)
      return :rate_limited if res["x-ratelimit-remaining"] == "0"

      REFUSALS.fetch(res.code) { res.is_a?(Net::HTTPServerError) ? :server_error : :forbidden }
    end
  end
end
