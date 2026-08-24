# frozen_string_literal: true

module CaptiveStackDetector
  # Connaissance « quel gem exige quels paquets système ». Rend les paires gem → paquets
  # pour les gems effectivement déclarés dans le Gemfile passé.
  module GemPackageMap
    MAP = {
      "ruby-vips"          => %w[libvips42 libvips-dev],
      "mini_magick"        => %w[imagemagick],
      "rmagick"            => %w[imagemagick],
      "wkhtmltopdf-binary" => %w[], # retiré de Debian Trixie, projet upstream abandonné
      "sqlite3"            => %w[libsqlite3-dev],
    }.freeze

    def self.matches(gemfile)
      content = gemfile.to_s
      MAP.select { |gem, _| content.match?(/gem ['"]#{Regexp.escape(gem)}['"]/) }
    end
  end
end
