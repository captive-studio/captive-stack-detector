# frozen_string_literal: true

require_relative "js_env_files"

module CaptiveStackDetector
  # Ne lit que les sources et les modèles d'environnement, jamais les secrets .env.
  class JsEnvDetector
    def initialize(reader)
      @reader = reader
    end

    def detect
      vars = @reader.list(".").sort.each_with_object({}) do |entry, found|
        path = entry.delete_prefix("./")
        parser = JsEnvFiles.parser(path)
        found.merge!(parser.scan(@reader.read(path).to_s)) if parser
      end
      vars.reject { |key, _| JsEnvScanner::RUNTIME_VARS.include?(key) }
    end
  end
end
