# frozen_string_literal: true

require "spec_helper"
require "captive_stack_detector/solid_queue_usage"

RSpec.describe CaptiveStackDetector::SolidQueueUsage do
  def usage(recurring_task_names: [], job_files: [])
    described_class.new(recurring_task_names: recurring_task_names, job_files: job_files).used?
  end

  it "n'est pas utilisé sans tâche récurrente ni job" do
    expect(usage).to be(false)
  end

  it "ignore la tâche clear_solid_queue_finished_jobs générée par défaut" do
    expect(usage(recurring_task_names: %w[clear_solid_queue_finished_jobs])).to be(false)
  end

  it "est utilisé si une autre tâche récurrente est déclarée" do
    expect(usage(recurring_task_names: %w[clear_solid_queue_finished_jobs sync_stats])).to be(true)
  end

  it "ignore application_job.rb" do
    expect(usage(job_files: %w[app/jobs/application_job.rb])).to be(false)
  end

  it "est utilisé si un job applicatif existe, y compris en sous-dossier" do
    expect(usage(job_files: %w[app/jobs/application_job.rb app/jobs/billing/invoice_job.rb])).to be(true)
  end
end
