# frozen_string_literal: true

module CaptiveStackDetector
  # Extrait les paquets système déclarés dans un Aptfile : un paquet par ligne,
  # commentaires (`#`) et lignes vides ignorés.
  module AptfileParser
    def self.parse(content)
      content.to_s.lines
             .map { |line| line.split("#", 2).first.to_s.strip }
             .reject(&:empty?)
    end
  end
end
