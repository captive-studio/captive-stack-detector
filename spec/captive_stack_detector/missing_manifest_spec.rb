# frozen_string_literal: true

require "spec_helper"
require "captive_stack_detector/missing_manifest"

RSpec.describe CaptiveStackDetector::MissingManifest do
  def error(paths) = described_class.error(double("reader", list: paths))

  it "qualifie de monorepo un dépôt dont seuls les sous-dossiers directs portent un manifeste" do
    paths = %w[./admin/package.json api/Gemfile api/package.json app/x/package.json README.md]

    expect(error(paths)).to have_attributes(reason: :monorepo, directories: %w[admin api])
  end

  it "refuse sans manifeste quand aucun sous-dossier n'en porte" do
    expect(error(%w[README.md app/x/package.json])).to have_attributes(reason: :no_manifest, directories: [])
  end
end
