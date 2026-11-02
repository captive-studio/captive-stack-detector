# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "fileutils"
require "json"
require "base64"
require "captive_stack_detector"

RSpec.describe CaptiveStackDetector::JsEnvDetector do
  let(:files) do
    {
      "package.json" => '{"scripts":{"build":"vite build"},"dependencies":{"astro":"6.0.0","vite":"8.0.0"}}',
      ".env.example" => "# COMMENT=ignored\nexport PUBLIC_API_URL=https://example.test\nTOKEN=never-copy-this-value\n",
      ".env.sample" => "SAMPLE=value\n",
      ".env.template" => "TEMPLATE=\nNODE_ENV=production\nPORT=3000\n",
      ".env" => "PRIVATE=never-read\n",
      ".env.production" => "PRIVATE_PRODUCTION=never-read\n",
      "src/pages/index.astro" => "---\nconst url = import.meta.env.PUBLIC_API_URL;\n---",
      "src/client.tsx" => 'import.meta.env.VITE_API_URL;',
      "src/server.mjs" => 'process.env.SECRET;',
      "vite.config.ts" => 'process.env.CONFIG_TOKEN;',
      "src/component.vue" => '<script>process.env.VUE_TOKEN;</script>',
      "src/component.svelte" => '<script>process.env.SVELTE_TOKEN;</script>',
      "src/optional.js" => 'process.env.OPTIONAL ?? "default";',
      "node_modules/pkg/index.js" => 'process.env.DEPENDENCY;',
      "dist/app.js" => 'process.env.BUILT;',
      ".output/server.js" => 'process.env.OUTPUT;',
      "scripts/admin.ts" => 'process.env.ADMIN_PASSWORD;',
      "tests/test.js" => 'process.env.TEST;',
      "src/component.test.ts" => 'process.env.TEST;',
      "src/component.spec.ts" => 'process.env.TEST;',
      "src/component.stories.tsx" => 'process.env.STORY;',
      "src/env.d.ts" => 'process.env.TYPE;',
    }
  end

  let(:expected_keys) { %w[PUBLIC_API_URL TOKEN SAMPLE TEMPLATE VITE_API_URL SECRET CONFIG_TOKEN VUE_TOKEN SVELTE_TOKEN] }

  it "détecte les sources et modèles en local sans copier leurs valeurs" do
    Dir.mktmpdir do |dir|
      files.each do |path, content|
        FileUtils.mkdir_p(File.dirname(File.join(dir, path)))
        File.write(File.join(dir, path), content)
      end
      result = CaptiveStackDetector.detect(local_path: dir)
      expect(result.env_vars).to eq(expected_keys.to_h { |key| [ key, "placeholder" ] })
      expect(result.public_env_prefix).to eq("PUBLIC_")
    end
  end

  it "détecte les mêmes clés via GitHub et ne télécharge pas les secrets ou fichiers exclus" do
    repo = "org/node-app"
    tree = files.keys.map { |path| { "path" => path, "type" => "blob" } }
    stub_request(:get, "https://api.github.com/repos/#{repo}/git/trees/HEAD?recursive=1")
      .to_return(body: JSON.generate({ "tree" => tree }))
    stub_request(:get, "https://api.github.com/repos/#{repo}/contents/Gemfile").to_return(status: 404)
    stub_request(:get, "https://api.github.com/repos/#{repo}/contents/Procfile").to_return(status: 404)
    %w[.nvmrc .tool-versions].each do |name|
      stub_request(:get, "https://api.github.com/repos/#{repo}/contents/#{name}").to_return(status: 404)
    end
    files.each do |path, content|
      next if path.start_with?("node_modules/", "dist/", ".output/", "tests/", "scripts/") || path.match?(/\.(?:test|spec|stories)\.|\.d\.ts\z/)
      next if %w[.env .env.production].include?(path)

      stub_request(:get, "https://api.github.com/repos/#{repo}/contents/#{path}")
        .to_return(body: JSON.generate({ "content" => Base64.strict_encode64(content) }))
    end
    result = CaptiveStackDetector.detect(github_token: "token", repo: repo)
    expect(result.env_vars.keys).to match_array(expected_keys)
    expect(WebMock).not_to have_requested(:get, "https://api.github.com/repos/#{repo}/contents/.env")
    expect(WebMock).not_to have_requested(:get, "https://api.github.com/repos/#{repo}/contents/.env.production")
  end

  it "ignore les fichiers devenus absents après leur énumération" do
    reader = double("reader", list: [ "src/gone.ts", ".env.example" ], read: nil)
    expect(described_class.new(reader).detect).to eq({})
  end
end
