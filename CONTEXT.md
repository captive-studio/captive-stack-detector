# Glossaire — captive-stack-detector

## Stack

Type de framework d'un repo, déterminé à partir du contenu de ses fichiers de configuration.

Valeurs supportées :

| Valeur | Condition |
| --- | --- |
| `rails` | Gemfile présent contenant `gem 'rails'` |
| `node` | package.json présent avec un script `"start"`, sans dépendance `expo` |
| `expo` | package.json présent avec la dépendance `expo` (script `"start"` non requis) |

Tout autre cas lève `CaptiveStackDetector::UnsupportedStack`. En particulier, un package.json sans script `"start"` (package npm, librairie, monorepo racine) n'est pas une stack déployable.

_Avoid_ : "type d'app", "langage", "framework détecté"

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
- `subtype` — précision sur le type Rails : `app` (assets présents) ou `api` (pas d'assets). Voir **RailsSubtype**. `nil` pour Node et Expo.
- `services.database` — `"postgres"` si dépendance détectée (`gem 'pg'` pour Rails ; `pg` ou `node-postgres` pour Node), `nil` sinon. Extensible à d'autres moteurs (`"mysql"`, etc.)
- `services.queue` — `"redis"` si dépendance détectée (`gem 'redis'`, `gem 'sidekiq'` pour Rails ; `redis` ou `ioredis` pour Node), `nil` sinon.
- `worker.command` — commande du worker : ligne `worker:` du Procfile en priorité, sinon `"bundle exec sidekiq"` si `gem 'sidekiq'` présent. `nil` si absent.
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

## FileContents

La gem opère dans deux modes :

**Mode local** (`local_path:`) : la gem lit directement les fichiers depuis le filesystem. Utilisé en CI (workflow `build-app.yml` via `captive-admin app:detect-stack`).

**Mode GitHub** (`github_token:` + `repo:`) : la gem fetche les fichiers via l'API GitHub REST avec le token fourni. Utilisé dans captive-dashboard lors de la création d'une app.

Dans les deux modes, les fichiers lus sont : `Gemfile`, `package.json`, `Procfile`, `.tool-versions`, `.nvmrc`, `config/storage.yml`.

---

## UnsupportedStack

Erreur levée quand aucun type supporté ne peut être déterminé à partir des fichiers fournis. Distinct d'une erreur technique : les fichiers ont bien été lus, mais leur contenu ne correspond à aucune stack connue.

_Avoid_ : "UnknownAppType" (terme interne hérité de captive-ruby)
