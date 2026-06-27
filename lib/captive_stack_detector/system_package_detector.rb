# frozen_string_literal: true

module CaptiveStackDetector
  class SystemPackageDetector
    GEM_TO_PACKAGES = {
      "ruby-vips"        => %w[libvips42 libvips-dev],
      "mini_magick"      => %w[imagemagick],
      "rmagick"          => %w[imagemagick],
      "wkhtmltopdf-binary" => %w[wkhtmltopdf],
      "sqlite3"          => %w[libsqlite3-dev],
    }.freeze

    def initialize(gemfile:, aptfile:)
      @gemfile = gemfile.to_s
      @aptfile = aptfile.to_s
    end

    def packages
      from_gemfile + from_aptfile
    end

    private

    def from_gemfile
      GEM_TO_PACKAGES.each_with_object([]) do |(gem, pkgs), result|
        result.concat(pkgs) if @gemfile.match?(/gem ['"]#{Regexp.escape(gem)}['"]/)
      end
    end

    def from_aptfile
      @aptfile.lines.map(&:strip).reject { |l| l.empty? || l.start_with?("#") }
    end
  end
end
