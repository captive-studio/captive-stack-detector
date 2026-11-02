# frozen_string_literal: true

require "strscan"
require_relative "js_env_syntax"

module CaptiveStackDetector
  # Énumère les accès littéraux en ignorant commentaires et texte non exécuté.
  class JsEnvLexer
    include JsEnvSyntax

    def initialize(content)
      @scanner = StringScanner.new(content, fixed_anchor: true)
      @references = []
    end

    def references
      code
      @references
    end

    private

    def code(terminator = nil)
      until @scanner.eos?
        next if @scanner.skip(IGNORED)

        break if consume == terminator
      end
    end

    def consume
      if @scanner.scan(ASTRO_IMPORT)
        astro_import(@scanner[1])
      elsif @scanner.scan(REFERENCE)
        reference
      else
        punctuation(@scanner.getch)
      end
    end

    def punctuation(char)
      code("}") if char == "{"
      template if char == "`"
      char
    end

    def astro_import(names)
      JsEnvSyntax.astro_keys(names).each { |key| @references << [ key, "astro", "" ] }
    end

    def reference
      scope = @scanner[1].start_with?("import") ? "vite" : "node"
      @references << [ @scanner[2] || @scanner[3], scope, @scanner.rest ]
    end

    def template
      until @scanner.eos? || @scanner.skip(/`/)
        code("}") if @scanner.skip(/\$\{/)
        @scanner.skip(/(?:\\.|[^`$]|\$(?!\{))+/m)
      end
    end
  end
end
