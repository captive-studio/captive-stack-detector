# frozen_string_literal: true

require "json"
require_relative "captive_stack_detector/types"
require_relative "captive_stack_detector/file_reader"
require_relative "captive_stack_detector/gemfile_analyzer"
require_relative "captive_stack_detector/rails_stack_detector"
require_relative "captive_stack_detector/js_stack_detector"
require_relative "captive_stack_detector/static_site_detector"
require_relative "captive_stack_detector/addon_recommender"

# Déduit d'un dépôt sa stack, ses services et les options d'add-on à recommander.
module CaptiveStackDetector
  # Doc publique des stacks supportées, livrée dans la gem et affichée par le dashboard (ADR 0003).
  DOC_PATH = File.expand_path("../docs/stacks.md", __dir__)

  def self.detect(local_path: nil, github_token: nil, repo: nil)
    reader = FileReader.build(local_path: local_path, github_token: github_token, repo: repo)
    detect_from(reader)
  end

  def self.detect_from(reader)
    AddonRecommender.new(reader).apply(detect_stack(reader))
  end
  private_class_method :detect_from

  def self.detect_stack(reader)
    gemfile      = reader.read("Gemfile")
    package_json = reader.read("package.json")

    return RailsStackDetector.new(reader, GemfileAnalyzer.new(gemfile)).detect if gemfile
    return JsStackDetector.new(reader, package_json).detect                    if package_json

    static_site = StaticSiteDetector.new(reader)
    raise UnsupportedStack, :no_manifest unless static_site.site?

    static_site.detect
  end
  private_class_method :detect_stack
end
