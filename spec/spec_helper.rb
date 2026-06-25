# frozen_string_literal: true

require "simplecov"
SimpleCov.start do
  minimum_coverage 100
  add_filter "/spec/"
end

require "rspec"
require "webmock/rspec"

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
