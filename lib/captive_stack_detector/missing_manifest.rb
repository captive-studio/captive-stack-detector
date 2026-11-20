# frozen_string_literal: true

require_relative "types"

module CaptiveStackDetector
  # Le refus d'un dépôt sans manifeste racine : un monorepo (admin/, api/…) est nommé comme tel,
  # plutôt que « aucun manifeste ».
  module MissingManifest
    SUBPROJECT_MANIFEST = %r{\A([^/]+)/(?:Gemfile|package\.json)\z}

    def self.error(reader)
      directories = reader.list(".").filter_map { |path| path.delete_prefix("./")[SUBPROJECT_MANIFEST, 1] }.uniq.sort
      return UnsupportedStack.new(:no_manifest) if directories.empty?

      UnsupportedStack.new(:monorepo, directories:)
    end
  end
end
