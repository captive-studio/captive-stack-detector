# frozen_string_literal: true

require "json"
require_relative "captive_stack_detector/types"
require_relative "captive_stack_detector/file_reader"
require_relative "captive_stack_detector/stack_router"
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
    AddonRecommender.new(reader).apply(StackRouter.new(reader).detect)
  end
  private_class_method :detect_from
end
