# frozen_string_literal: true

module CaptiveStackDetector
  class SystemPackageDetector
    GEM_TO_PACKAGES = {
      "ruby-vips"        => %w[libvips42 libvips-dev],
      "mini_magick"      => %w[imagemagick],
      "rmagick"          => %w[imagemagick],
      "wkhtmltopdf-binary" => %w[], # retiré de Debian Trixie, projet upstream abandonné
      "sqlite3"          => %w[libsqlite3-dev],
    }.freeze

    def initialize(gemfile:, aptfile:)
      @gemfile = gemfile.to_s
      @aptfile = aptfile.to_s
    end

    def packages
      result = (from_gemfile + from_aptfile).uniq
      $stderr.puts "[captive-stack-detector] paquets système détectés : #{result.any? ? result.join(", ") : "aucun"}"
      result
    end

    private

    def from_gemfile
      GEM_TO_PACKAGES.each_with_object([]) do |(gem, pkgs), result|
        next unless @gemfile.match?(/gem ['"]#{Regexp.escape(gem)}['"]/)

        $stderr.puts "[captive-stack-detector] gem '#{gem}' détecté → #{pkgs.any? ? pkgs.join(", ") : "aucun paquet"}"
        result.concat(pkgs)
      end
    end

    def from_aptfile
      packages = @aptfile.lines.map { |line| line.split("#", 2).first.to_s.strip }.reject(&:empty?)
      packages.each { |pkg| $stderr.puts "[captive-stack-detector] Aptfile → paquet '#{pkg}'" }
      packages
    end
  end
end
