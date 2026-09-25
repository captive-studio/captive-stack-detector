# frozen_string_literal: true

require_relative "solid_queue_usage"
require_relative "recurring_schedule"

module CaptiveStackDetector
  class SolidQueueWorker
    COMMAND = "bin/jobs"

    def initialize(reader, analyzer)
      @reader   = reader
      @analyzer = analyzer
    end

    def command
      COMMAND if @analyzer.solid_queue? && usage.used?
    end

    private

    def usage
      SolidQueueUsage.new(
        recurring_task_names: RecurringSchedule.new(@reader.read("config/recurring.yml")).task_names,
        job_files:            @reader.list("app/jobs"),
      )
    end
  end
end
