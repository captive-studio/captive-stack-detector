# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "fileutils"
require "json"
require "captive_stack_detector"

RSpec.describe CaptiveStackDetector::AddonRecommender do
  around do |example|
    Dir.mktmpdir do |dir|
      @dir = dir
      example.run
    end
  end

  def write(path, content = "x")
    FileUtils.mkdir_p(File.dirname(File.join(@dir, path)))
    File.write(File.join(@dir, path), content)
  end

  def recommendations = CaptiveStackDetector.detect(local_path: @dir).recommendations

  def options = recommendations.map(&:option)

  def static_supabase
    write("index.html")
    write("supabase/config.toml")
  end

  it "ne recommande rien au front Deal-Flow qui ne fait que se connecter et gérer la MFA" do
    static_supabase
    write("app.js", <<~JS)
      await supabase.auth.signInWithPassword({ email, password });
      await supabase.auth.mfa.enroll({ factorType: "totp" });
    JS

    expect(recommendations).to eq([])
  end

  it "recommande smtp avec sa raison quand le code envoie des emails d'auth" do
    static_supabase
    write("app.js", "await supabase.auth.signUp({ email, password });")

    expect(recommendations).to eq([
      CaptiveStackDetector::Recommendation.new(addon: "supabase", option: "smtp", reason: "votre code appelle signUp"),
    ])
  end

  {
    "supabase.auth.resetPasswordForEmail(email)" => "resetPasswordForEmail",
    "supabase.auth.signInWithOtp({ email })" => "signInWithOtp",
    "admin.inviteUserByEmail(email)" => "inviteUserByEmail",
    "supabase.auth.updateUser({ email: next })" => "updateUser",
  }.each do |code, call|
    it "recommande smtp pour #{call}" do
      static_supabase
      write("js/auth.ts", code)

      expect(recommendations.map(&:reason)).to eq([ "votre code appelle #{call}" ])
    end
  end

  it "ne recommande pas smtp pour un updateUser sans email" do
    static_supabase
    write("js/auth.ts", "supabase.auth.updateUser({ password })")

    expect(recommendations).to eq([])
  end

  it "recommande realtime, pg_cron et vault d'après le code et le SQL du dépôt" do
    write("package.json", { "scripts" => { "build" => "vite build" },
                            "dependencies" => { "@supabase/supabase-js" => "2" }, }.to_json)
    write("src/live.ts", "supabase.channel('room').on('postgres_changes', cb)")
    write("supabase/migrations/1_cron.sql", "select cron.schedule('x', '* * * * *', 'select 1');")
    write("db/secrets.sql", "select vault.create_secret('k');")

    expect(options).to eq(%w[realtime pg_cron vault])
  end

  it "voit pg_net comme un besoin de pg_cron" do
    static_supabase
    write("supabase/migrations/2_net.sql", "select net.http_post(url := 'https://x');")

    expect(recommendations.map(&:reason)).to eq([ "votre SQL appelle net.http_" ])
  end

  it "ignore dépendances, builds et tests" do
    static_supabase
    write("node_modules/@supabase/auth-js/index.js", "signUp(")
    write("dist/app.js", "signUp(")
    write("tests/auth.test.js", "signUp(")
    write("node_modules/x/cron.sql", "cron.schedule(")

    expect(recommendations).to eq([])
  end

  it "ne recommande rien sans backend Supabase" do
    write("index.html")
    write("app.js", "signUp(")

    expect(recommendations).to eq([])
  end
end
