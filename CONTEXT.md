# Glossaire — captive-stack-detector

## Stack

Type de framework d'un repo, déterminé à partir du contenu de ses fichiers de configuration. La détection est une analyse pure : la gem reçoit des strings, elle rend un résultat — aucun accès réseau ni filesystem.

Valeurs supportées :

| Valeur | Condition |
|---|---|
| `rails` | Gemfile présent contenant `gem 'rails'` |
| `node` | package.json présent, sans dépendance `expo` |
| `expo` | package.json présent avec la dépendance `expo` |

Tout autre cas lève `CaptiveStackDetector::UnsupportedStack`.

_Avoid_ : "type d'app", "langage", "framework détecté"

---

## StackResult

Résultat complet de la détection, retourné par `CaptiveStackDetector.detect(...)`. Contient :

- `type` — valeur de Stack (`rails`, `node`, `expo`)
- `subtype` — précision sur le type Rails : `app` (assets présents : sprockets, propshaft, importmap) ou `api` (pas d'assets)
- `with_postgres` — le repo déclare une dépendance postgres (`gem 'pg'` ou `pg` dans package.json)
- `with_redis` — le repo déclare une dépendance redis (`gem 'redis'`, `gem 'sidekiq'`, ou `redis`/`ioredis` dans package.json)
- `worker_command` — commande du worker extraite du Procfile (ligne `worker: …`), nil si absente
- `required_env_vars` — variables d'environnement requises détectées dans les fichiers de config (ex: `config/storage.yml`)

---

## FileContents

Ensemble des contenus de fichiers fournis par le caller pour la détection. La gem n'accède à aucun fichier elle-même : c'est le caller (captive-dashboard, captive-admin, etc.) qui est responsable du fetch.

Fichiers utilisés : `Gemfile`, `package.json`, `Procfile`, fichiers sous `config/`.

---

## UnsupportedStack

Erreur levée quand aucun type supporté ne peut être déterminé à partir des fichiers fournis. Distinct d'une erreur technique : les fichiers ont bien été lus, mais leur contenu ne correspond à aucune stack connue.

_Avoid_ : "UnknownAppType" (terme interne hérité de captive-ruby)
