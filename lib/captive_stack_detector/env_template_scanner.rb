# frozen_string_literal: true

module CaptiveStackDetector
  # Les modèles déclarent des noms ; leurs valeurs d'exemple ne sont jamais importées.
  module EnvTemplateScanner
    def self.scan(content)
      content.scan(/^\s*(?:export\s+)?([A-Z_][A-Z0-9_]*)\s*=/).flatten.to_h { |key| [ key, "placeholder" ] }
    end
  end
end
