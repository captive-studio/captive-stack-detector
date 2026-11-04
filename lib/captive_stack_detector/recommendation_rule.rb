# frozen_string_literal: true

require_relative "types"

module CaptiveStackDetector
  # Une option d'add-on et les appels qui la justifient ; le groupe nommé call est l'appel cité dans la raison.
  class RecommendationRule < Data.define(:option, :kind, :pattern)
    LABELS = { js: "votre code", sql: "votre SQL" }.freeze

    def recommend(sources)
      call = pattern.match(sources.of(kind))&.[](:call)
      call && Recommendation.new(addon: "supabase", option: option, reason: "#{LABELS.fetch(kind)} appelle #{call}")
    end
  end
end
