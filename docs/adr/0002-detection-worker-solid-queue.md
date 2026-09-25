# ADR 0002 — Détection du worker Solid Queue par gem + signal d'usage

## Statut

Accepté

## Contexte

captive-admin crée un Deployment `*-worker.yaml` uniquement si le StackResult contient un `worker`. Pour Rails, la détection se limitait à : ligne `worker:` du Procfile, sinon `gem 'sidekiq'`, sinon rien.

Les apps Rails 8 utilisent `solid_queue`, non détecté. captive-dashboard (`gem "solid_queue"`, jobs récurrents dans `config/recurring.yml`, pas de Procfile) s'est retrouvée sans worker : ses jobs ne tournent ni en staging ni en production.

La présence de la gem ne suffit pas : `solid_queue` est ajoutée par défaut par le générateur Rails 8, et `config.active_job.queue_adapter = :solid_queue` est aussi par défaut. De plus, l'installeur Solid Queue génère un `recurring.yml` contenant déjà une tâche active `production.clear_solid_queue_finished_jobs`. Aucun de ces éléments ne prouve un usage réel.

## Décision

Ordre de résolution du worker d'une app Rails :

1. Ligne `worker: <cmd>` du Procfile → `<cmd>`
2. `gem 'sidekiq'` → `bundle exec sidekiq`
3. `gem 'solid_queue'` **et** au moins un signal d'usage → `bin/jobs`
4. Sinon → pas de worker

Signaux d'usage Solid Queue (un seul suffit) :

- **Tâche récurrente** : `config/recurring.yml` contient au moins une tâche, tous environnements confondus, autre que `clear_solid_queue_finished_jobs`. Le fichier est parsé en YAML ; un YAML absent ou invalide vaut « pas de signal ».
- **Job applicatif** : `app/jobs/` contient au moins un fichier `.rb` autre que `application_job.rb`.

Le worker tourne toujours dans un Deployment séparé : `config/puma.rb` (`plugin :solid_queue`) n'est pas analysé.

Aucun mécanisme de désactivation explicite du worker n'est ajouté.

## Raisons

- **Faux positif préféré au faux négatif** : un worker inutile consomme des ressources ; un worker manquant fait échouer silencieusement des jobs métier (cas captive-dashboard).
- **Sidekiq avant Solid Queue** : `sidekiq` dans un Gemfile est toujours un choix explicite, `solid_queue` peut n'être qu'un résidu du template Rails. En cas de migration, Sidekiq gagne tant qu'il est présent.
- **Exclusion de `clear_solid_queue_finished_jobs`** : sans elle, toute app Rails 8 fraîchement générée aurait un worker.
- **Pas de filtre par environnement** : la détection est faite une fois pour staging et production.
- **Deployment séparé plutôt que Puma** : avec plusieurs replicas web, le plugin Puma démultiplie le scheduler et couple le scaling des jobs à celui du web.
- **`bin/jobs`** : binstub officiel de Rails 8.
- **Pas de désactivation** : les jobs imposant un Deployment séparé, il n'existe pas de cas légitime « jobs sans worker ». YAGNI.

Alternatives écartées :

- Gem seule : faux positif systématique sur toutes les apps Rails 8.
- Exiger un Procfile : c'est la règle actuelle, et elle a déjà échoué silencieusement.
- `recurring.yml` seul : rate les apps qui n'ont que des jobs `perform_later`.

## Conséquences

- La liste des fichiers lus (voir FileContents) s'étend à `config/recurring.yml`.
- Le lecteur de fichiers expose `list(dir)` (récursif) dans les deux modes. En mode GitHub, il utilise l'API Trees (`git/trees/HEAD?recursive=1`) : un seul appel quelle que soit la profondeur.
- `config/recurring.yml` et `app/jobs/` ne sont lus que si `gem 'solid_queue'` est présente : aucun appel supplémentaire pour les autres apps.
- Trou accepté : une app qui n'utilise que `deliver_later` (ActionMailer), sans tâche récurrente ni job dans `app/jobs/`, n'aura pas de worker. Solution de contournement : `worker: bin/jobs` dans le Procfile.
- Une app qui supprime `bin/jobs` du repo mais est détectée Solid Queue aura un worker en crash : risque jugé négligeable.
