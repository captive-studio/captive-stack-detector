# frozen_string_literal: true

require_relative "recommendation_rule"
require_relative "repo_sources"

module CaptiveStackDetector
  # Propose les options de l'add-on Supabase que le code du dépôt utilise, chacune avec sa raison.
  class AddonRecommender
    # Appels d'auth qui envoient un email ; signInWithPassword et auth.mfa n'en envoient pas.
    AUTH_EMAILS = /
      \b(?<call>signUp|resetPasswordForEmail|signInWithOtp|inviteUserByEmail)\(
      | \b(?<call>updateUser)\(\s*\{\s*email\b
    /x
    RULES = [
      RecommendationRule.new("smtp", :js, AUTH_EMAILS),
      RecommendationRule.new("realtime", :js, /\.(?<call>channel)\(|(?<call>postgres_changes)/),
      RecommendationRule.new("pg_cron", :sql, /\b(?<call>cron\.schedule|net\.http_)/),
      RecommendationRule.new("vault", :sql, /\b(?<call>vault)\./),
    ].freeze

    def initialize(reader)
      @reader = reader
    end

    # Seul Supabase a des options : les autres stacks gardent recommendations vide, sans lire les sources.
    def apply(result)
      return result unless result.services.backend == "supabase"

      sources = RepoSources.new(@reader)
      result.with(recommendations: RULES.filter_map { |rule| rule.recommend(sources) })
    end
  end
end
