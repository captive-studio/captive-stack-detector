# frozen_string_literal: true

require_relative "js_env_files"

module CaptiveStackDetector
  # Contenu des sources JS et SQL du dépôt, hors dépendances, builds et tests (mêmes exclusions que JsEnvFiles).
  class RepoSources
    def self.kind(path)
      return nil if JsEnvFiles::EXCLUDED.match?(path)
      return :sql if path.end_with?(".sql")

      :js if JsEnvFiles::SOURCE.match?(path)
    end

    def initialize(reader)
      @reader = reader
      @paths  = reader.list(".").sort.map { |entry| entry.delete_prefix("./") }.group_by { |path| self.class.kind(path) }
    end

    # Tout le code d'un genre (:js ou :sql), fichier par fichier, en un seul texte.
    def of(kind) = @paths.fetch(kind, []).map { |path| @reader.read(path).to_s }.join("\n")
  end
end
