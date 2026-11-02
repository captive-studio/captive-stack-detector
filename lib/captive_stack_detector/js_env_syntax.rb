# frozen_string_literal: true

module CaptiveStackDetector
  # Tokens reconnus sans interpréter le programme JavaScript.
  module JsEnvSyntax
    KEY = /[A-Z_][A-Z0-9_]*/
    REFERENCE = /
      (?<![\w$.])(process\s*\.\s*env|import\s*\.\s*meta\s*\.\s*env)
      (?:\s*\.\s*(#{KEY})(?![\w$])|\s*\[\s*['"](#{KEY})['"]\s*\])
    /x
    ASTRO_IMPORT = /import\s*\{([^}]+)\}\s*from\s*['"]astro:env\/(?:client|server)['"]/m
    COMMENT = %r{//[^\n]*|/\*.*?\*/|<!--.*?-->}m
    IGNORED = Regexp.union(COMMENT, /"(?:\\.|[^"\\])*"|'(?:\\.|[^'\\])*'/m)
    def self.astro_keys(names)
      names.gsub(COMMENT, "").split(",").filter_map { |name| name.strip[/\A#{KEY}\b/] }
    end
  end
end
