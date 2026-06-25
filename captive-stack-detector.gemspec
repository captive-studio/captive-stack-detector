# frozen_string_literal: true

require_relative "lib/captive_stack_detector/version"

Gem::Specification.new do |spec|
  spec.name    = "captive-stack-detector"
  spec.version = CaptiveStackDetector::VERSION
  spec.authors = [ "Captive Studio" ]
  spec.email   = [ "dev@captive.fr" ]

  spec.summary     = "Détection de stack (Rails, Node, Expo) à partir du contenu de fichiers de repo"
  spec.description = "Logique pure sans I/O : reçoit des strings de contenu de fichiers, retourne un StackResult typé."
  spec.homepage    = "https://github.com/captive-studio/captive-stack-detector"
  spec.license     = "MIT"

  spec.required_ruby_version = ">= 3.2"

  spec.files = Dir["lib/**/*.rb"]
end
