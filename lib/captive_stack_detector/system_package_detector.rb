# frozen_string_literal: true

require_relative "aptfile_parser"
require_relative "gem_package_map"

module CaptiveStackDetector
  # Paquets APT à installer dans l'image : ceux qu'exigent les gems du Gemfile/Gemfile.lock, plus l'Aptfile.
  class SystemPackageDetector
    def initialize(gemfile:, aptfile:, lockfile: nil)
      @gem_sources = [ gemfile, lockfile ]
      @aptfile = aptfile.to_s
    end

    def packages
      result = (from_gemfile + from_aptfile).uniq
      $stderr.puts "[captive-stack-detector] paquets système détectés : #{describe(result, "aucun")}"
      result
    end

    private

    def from_gemfile
      GemPackageMap.matches(*@gem_sources).each_with_object([]) do |(gem, pkgs), result|
        $stderr.puts "[captive-stack-detector] gem '#{gem}' détecté → #{describe(pkgs, "aucun paquet")}"
        result.concat(pkgs)
      end
    end

    def describe(pkgs, none)
      pkgs.any? ? pkgs.join(", ") : none
    end

    def from_aptfile
      AptfileParser.parse(@aptfile).each do |pkg|
        $stderr.puts "[captive-stack-detector] Aptfile → paquet '#{pkg}'"
      end
    end
  end
end
