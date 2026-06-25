# ADR 0001 — La gem gère le I/O elle-même

## Statut

Accepté

## Contexte

La première version de la gem était pure (pas de I/O) : elle recevait les contenus de fichiers en strings et retournait un résultat. Avec l'ajout de champs supplémentaires (worker_command depuis Procfile, required_env_vars depuis config/storage.yml, ruby_version depuis .tool-versions, node_version depuis .nvmrc), l'interface `detect(gemfile:, package_json:, procfile:, storage_yml:, ...)` devenait sans fin et difficile à utiliser.

## Décision

La gem gère le I/O elle-même et opère dans deux modes :

- `CaptiveStackDetector.detect(local_path: "/path/to/app")` — lit les fichiers depuis le filesystem
- `CaptiveStackDetector.detect(github_token: "gho_...", repo: "captive-studio/mon-app")` — fetche les fichiers via l'API GitHub REST

La logique de détection interne reste pure et testable indépendamment du mode d'accès aux fichiers.

## Raisons

Ajouter un paramètre par fichier (`procfile:`, `storage_yml:`, `.tool-versions`, `.nvmrc`) rend l'interface ingérable et force chaque caller à connaître exactement quels fichiers la gem a besoin. La gem est mieux placée pour savoir quels fichiers lire.

L'alternative d'un client injecté (duck-typing) a été écartée : elle transfère la complexité au caller sans gain réel, et oblige chaque contexte (dashboard, captive-admin, tests) à implémenter son propre adaptateur.

## Conséquences

- La gem embarque un client HTTP minimal pour l'accès GitHub (pas de dépendance externe lourde).
- captive-ruby/StackDetector est remplacé par un appel direct à la gem.
- captive-dashboard/FrameworkDetector passe son `github_token` directement à la gem.
- captive-admin/app:detect-stack passe `local_path` à la gem.
- Les tests unitaires de la logique de détection continuent d'utiliser des fixtures strings ; les tests d'intégration utilisent un tmpdir ou un stub HTTP.
