# frozen_string_literal: true

source "https://rubygems.org"

ruby File.read(File.join(__dir__, ".tool-versions")).match(/^ruby (.+)$/)[1].strip

gemspec

group :development, :test do
  gem "rubocop-config-captive", "~> 2.0", require: false
end

group :test do
  gem "rspec"
  gem "simplecov", require: false
  gem "rubycritic", require: false
end

gem "webmock", "~> 3.26", group: :test
