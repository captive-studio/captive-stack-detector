# frozen_string_literal: true

module CaptiveStackDetector
  class SolidQueueUsage
    DEFAULT_RECURRING_TASK = "clear_solid_queue_finished_jobs"
    DEFAULT_JOB_FILE       = "application_job.rb"

    def initialize(recurring_task_names:, job_files:)
      @recurring_task_names = recurring_task_names
      @job_files            = job_files
    end

    def used? = recurring_task? || application_job?

    private

    def recurring_task? = @recurring_task_names.any? { |task| task != DEFAULT_RECURRING_TASK }

    def application_job?
      @job_files.any? { |file| file.end_with?(".rb") && File.basename(file) != DEFAULT_JOB_FILE }
    end
  end
end
