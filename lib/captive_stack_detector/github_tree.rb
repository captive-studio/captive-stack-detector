# frozen_string_literal: true

require "json"

module CaptiveStackDetector
  class GithubTree
    def initialize(body)
      @entries = JSON.parse(body)["tree"]
    end

    def files_in(dir)
      prefix = "#{dir}/"
      @entries.filter_map { |entry| entry["path"] if entry["type"] == "blob" && entry["path"].start_with?(prefix) }
    end
  end
end
