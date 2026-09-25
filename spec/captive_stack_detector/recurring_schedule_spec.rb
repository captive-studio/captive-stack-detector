# frozen_string_literal: true

require "spec_helper"
require "captive_stack_detector/recurring_schedule"

RSpec.describe CaptiveStackDetector::RecurringSchedule do
  it "liste les tâches de tous les environnements" do
    yml = "production:\n  a:\n    command: x\nstaging:\n  b:\n    command: y\n"
    expect(described_class.new(yml).task_names).to eq(%w[a b])
  end

  it "retourne une liste vide pour un YAML absent, commenté ou invalide" do
    expect(described_class.new(nil).task_names).to eq([])
    expect(described_class.new("# foo:\n").task_names).to eq([])
    expect(described_class.new("production: [oops").task_names).to eq([])
  end
end
