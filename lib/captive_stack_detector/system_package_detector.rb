# frozen_string_literal: true

require_relative "aptfile_parser"
require_relative "gem_package_map"

module CaptiveStackDetector
  class SystemPackageDetector
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
      GemPackageMap.matches(@gemfile).each_with_object([]) do |(gem, pkgs), result|
        $stderr.puts "[captive-stack-detector] gem '#{gem}' détecté → #{pkgs.any? ? pkgs.join(", ") : "aucun paquet"}"
        result.concat(pkgs)
      end
    end

    def from_aptfile
      AptfileParser.parse(@aptfile).each do |pkg|
        $stderr.puts "[captive-stack-detector] Aptfile → paquet '#{pkg}'"
      end
    end
  end
end
