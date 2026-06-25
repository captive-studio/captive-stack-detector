# frozen_string_literal: true

module CaptiveStackDetector
  class RubyVersionDetector
    def initialize(reader)
      @reader = reader
    end

    def detect
      return from_tool_versions if @reader.read(".tool-versions")
      return from_ruby_version   if @reader.read(".ruby-version")
      return from_gemfile        if @reader.read("Gemfile")

      nil
    end

    private

    def from_tool_versions
      @reader.read(".tool-versions")&.match(/^ruby\s+(\S+)/)&.[](1)
    end

    def from_ruby_version
      @reader.read(".ruby-version")&.strip&.sub(/^ruby-/, "")
    end

    def from_gemfile
      @reader.read("Gemfile")&.match(/^\s*ruby\s+['"](\d+\.\d+\.\d+)['"]/)&.[](1)
    end
  end
end
