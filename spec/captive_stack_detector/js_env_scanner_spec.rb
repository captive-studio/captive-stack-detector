# frozen_string_literal: true

require "spec_helper"
require "captive_stack_detector/js_env_scanner"

RSpec.describe CaptiveStackDetector::JsEnvScanner do
  it "détecte les lectures Vite, Astro et Node avec clé littérale" do
    source = <<~JS
      import.meta.env.VITE_API_URL;
      import.meta.env['PUBLIC_API_URL'];
      process.env.SECRET;
      process.env["TOKEN"];
      process . env . SPACED;
      process.env.SECRET;
    JS
    expect(described_class.scan(source)).to eq(%w[VITE_API_URL PUBLIC_API_URL SECRET TOKEN SPACED].to_h { |k| [ k, "placeholder" ] })
  end

  it "ignore commentaires, exemples dans les chaînes et clés calculées" do
    source = <<~JS
      // process.env.COMMENT
      /* import.meta.env.BLOCK */
      <!-- import.meta.env.HTML -->
      "process.env.DOUBLE";
      'process.env.SINGLE';
      'escaped \\' process.env.QUOTED';
      `process.env.TEXT`;
      process.env[name];
      other.process.env.NESTED;
      process.env.UPPERlower;
    JS
    expect(described_class.scan(source)).to eq({})
  end

  it "lit les interpolations des templates sans lire leur texte" do
    source = '`process.env.TEXT ${process.env.TOKEN} ${JSON.stringify({ key: process.env.API_KEY })} \\` fin`'
    expect(described_class.scan(source).keys).to eq(%w[TOKEN API_KEY])
  end

  it "ignore les valeurs par défaut littérales et les écritures" do
    source = <<~JS
      process.env.A ?? "fallback";
      process.env.B || 'fallback';
      process.env.C ?? 123;
      process.env.D || false;
      process.env.E ?? true;
      process.env.F = "written";
      process.env.G ||= "written";
      process.env.H ??= "written";
      process.env.I &&= "written";
      process.env.REQUIRED ?? computeDefault();
      process.env.COMPARE === "value";
    JS
    expect(described_class.scan(source).keys).to eq(%w[REQUIRED COMPARE])
  end

  it "conserve une variable obligatoire ailleurs même si elle a un défaut à une autre lecture" do
    expect(described_class.scan('process.env.TOKEN ?? "local"; process.env.TOKEN;')).to eq("TOKEN" => "placeholder")
  end

  it "ignore les constantes Vite et les variables du runtime, sans ignorer process.env.MODE" do
    source = 'import.meta.env.MODE; import.meta.env.BASE_URL; import.meta.env.DEV; import.meta.env.PROD; import.meta.env.SSR; ' \
             'process.env.PORT; process.env.HOST; process.env.NODE_ENV; process.env.NODE_OPTIONS; process.env.MODE;'
    expect(described_class.scan(source)).to eq("MODE" => "placeholder")
  end

  it "détecte les imports Astro env publics et serveur, avec alias" do
    source = <<~JS
      import { PUBLIC_URL, PUBLIC_KEY as key } from 'astro:env/client';
      import { SECRET, /* annotation */ SERVER_TOKEN as token, getSecret } from "astro:env/server";
    JS
    expect(described_class.scan(source).keys).to eq(%w[PUBLIC_URL PUBLIC_KEY SECRET SERVER_TOKEN])
  end

  it "termine sur un template incomplet" do
    expect(described_class.scan('`texte ${process.env.TOKEN')).to eq("TOKEN" => "placeholder")
  end
end
