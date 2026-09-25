# frozen_string_literal: true

require "yaml"

module CaptiveStackDetector
  class RecurringSchedule
    def initialize(yml)
      @yml = yml
    end

    def task_names
      environments.values.grep(Hash).flat_map(&:keys)
    end

    private

    def environments
      parsed = YAML.safe_load(@yml.to_s)
      parsed.is_a?(Hash) ? parsed : {}
    rescue Psych::Exception
      {}
    end
  end
end
