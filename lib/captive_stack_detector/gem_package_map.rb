# frozen_string_literal: true

module CaptiveStackDetector
  # Connaissance « quel gem exige quels paquets système ». Rend les paires gem → paquets
  # pour les gems déclarés dans le Gemfile ou résolus dans le Gemfile.lock (dépendances transitives).
  module GemPackageMap
    MAP = {
      "ruby-vips"          => %w[libvips42 libvips-dev],
      "mini_magick"        => %w[imagemagick],
      "rmagick"            => %w[imagemagick],
      "wkhtmltopdf-binary" => %w[], # retiré de Debian Trixie, projet upstream abandonné
      "sqlite3"            => %w[libsqlite3-dev],
      "ethon"              => %w[libcurl4t64], # charge libcurl via FFI (dépendance de typhoeus)
    }.freeze

    def self.matches(*sources)
      content = sources.join("\n")
      MAP.select { |gem, _| content.match?(pattern(gem)) }
    end

    # Déclaration `gem "x"` du Gemfile, ou spec résolue `    x (1.2.3)` du Gemfile.lock.
    def self.pattern(gem)
      name = Regexp.escape(gem)
      /gem ['"]#{name}['"]|^ {4}#{name} \(/
    end
  end
end
