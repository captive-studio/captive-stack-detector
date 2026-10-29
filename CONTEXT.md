# Glossaire — captive-stack-detector

## Stack

Type de framework d'un repo, déterminé à partir du contenu de ses fichiers de configuration.

Valeurs supportées :

| Valeur | Condition |
| --- | --- |
| `rails` | Gemfile présent contenant `gem 'rails'` |
| `node` | package.json présent avec un script `"start"` ou `"build"`, sans dépendance `expo` |
| `expo` | package.json présent avec la dépendance `expo` (script `"start"` non requis) |

Tout autre cas lève `CaptiveStackDetector::UnsupportedStack`, avec une **UnsupportedReason**. Un package.json sans script `"start"` ni `"build"` (package npm, monorepo racine) n'est pas une stack déployable.

_Avoid_ : "type d'app", "langage", "framework détecté"

---

## SPA

Stack `node` sans subtype : le dépôt est buildé (`build` produit `dist/`) puis servi en fichiers statiques, sans process Node au runtime.

_Avoid_ : "static", "site statique", "front Vite"

---

## Préfixe public

Préfixe des variables d'environnement que le bundler front d'une stack JS expose au navigateur : `EXPO_PUBLIC_` (expo), `NEXT_PUBLIC_` (next), `VITE_` (vite), dans cet ordre de priorité. `nil` sans bundler front. La plateforme pose sous ce préfixe ce que le front doit lire au build, comme l'URL et la clé publique Supabase.

_Avoid_ : "préfixe Next", "variables front"

---

## UnsupportedReason

Raison pour laquelle un dépôt n'est pas une Stack déployable.

| Valeur | Cas |
| --- | --- |
| `no_manifest` | Ni Gemfile ni package.json à la racine |
| `no_rails` | Gemfile sans la gem `rails` |
| `no_node_entry` | package.json sans dépendance `expo` ni script `start` ou `build` |

---

## StackResult

Résultat complet de la détection, retourné par `CaptiveStackDetector.detect(...)`. Structure :

```json
{
  "type": "rails",
  "subtype": "app",
  "services": {
    "database": "postgres",
    "queue": "redis"
  },
  "worker": { "command": "bundle exec sidekiq" },
  "runtime": { "ruby": "3.4", "node": null },
  "env_vars": { "S3_BUCKET": "placeholder" }
}
```

- `type` — valeur de Stack (`rails`, `node`, `expo`)
- `subtype` — précision sur le type Rails : `app` (assets présents) ou `api` (pas d'assets). Voir **RailsSubtype**. Pour Node : `server` avec Next, Nuxt, SvelteKit, Remix ou l'adaptateur `@astrojs/node` ; `nil` pour les fichiers statiques, dont Astro sans adaptateur Node. `nil` pour Expo.
- `services.database` — `"postgres"` si dépendance détectée (`gem 'pg'` pour Rails ; `pg` ou `postgres` (postgres.js) pour Node ; les ORM comme Prisma ou Drizzle ne comptent pas, ils parlent aussi d'autres moteurs), `nil` sinon. Extensible à d'autres moteurs (`"mysql"`, etc.)
- `services.queue` — `"redis"` si dépendance détectée (`gem 'redis'`, `gem 'sidekiq'` pour Rails ; `redis` ou `ioredis` pour Node), `nil` sinon.
- `worker.command` — commande du worker, par ordre de priorité : ligne `worker:` du Procfile ; `"bundle exec sidekiq"` si `gem 'sidekiq'` ; `"bin/jobs"` si `gem 'solid_queue'` **et** un **SolidQueueUsage**. `nil` sinon. Voir ADR 0002.
- `runtime.ruby` — version Ruby extraite de `.tool-versions`, `nil` si absente.
- `runtime.node` — version Node extraite de `.nvmrc`, `.tool-versions`, ou `package.json engines.node`, `nil` si absente.
- `env_vars` — Hash des variables d'environnement requises détectées dans `config/storage.yml` (clé → `"placeholder"`). `{}` si aucune.

---

## RailsSubtype

Précision sur une stack Rails indiquant si le repo gère des assets frontend.

| Valeur | Condition |
| --- | --- |
| `app` | Gemfile contient au moins une gem d'assets : `sprockets`, `sprockets-rails`, `propshaft`, `importmap-rails`, `cssbundling-rails`, `jsbundling-rails`, `dartsass-rails`, `tailwindcss-rails` |
| `api` | Aucune gem d'assets détectée |

Le subtype détermine quel Dockerfile est utilisé : `rails-app` (avec pipeline Node) ou `rails-api` (Ruby seul).

_Avoid_ : "mode API", "API-only"

---

## SolidQueueUsage

Preuve qu'une app Rails utilise réellement Solid Queue, au-delà de la gem ajoutée par défaut par Rails 8. Au moins un signal parmi :

- **Tâche récurrente** : `config/recurring.yml` déclare une tâche (tous environnements) autre que `clear_solid_queue_finished_jobs`, générée par défaut.
- **Job applicatif** : `app/jobs/` contient un fichier `.rb` autre que `application_job.rb`.

_Avoid_ : "solid_queue détecté" (la gem seule n'est pas un usage)

---

## FileContents

La gem opère dans deux modes :

**Mode local** (`local_path:`) : la gem lit directement les fichiers depuis le filesystem. Utilisé en CI (workflow `build-app.yml` via `captive-admin app:detect-stack`).

**Mode GitHub** (`github_token:` + `repo:`) : la gem fetche les fichiers via l'API GitHub REST avec le token fourni. Utilisé dans captive-dashboard lors de la création d'une app.

Dans les deux modes, les fichiers lus sont : `Gemfile`, `package.json`, `Procfile`, `.tool-versions`, `.nvmrc`, `config/storage.yml`, `config/recurring.yml`. Le dossier `app/jobs/` est listé (sans lecture du contenu).

---

## UnsupportedStack

Erreur levée quand aucun type supporté ne peut être déterminé à partir des fichiers fournis. Distinct d'une erreur technique : les fichiers ont bien été lus, mais leur contenu ne correspond à aucune stack connue.

_Avoid_ : "UnknownAppType" (terme interne hérité de captive-ruby)
