# Stacks supportées

Quand vous créez une application, Captive lit votre dépôt GitHub pour savoir **comment le construire et le lancer**. Cette famille de déploiement s'appelle la **stack**. Captive en connaît trois : **Rails**, **Node** et **Expo**. Si votre dépôt n'entre dans aucune, la création est refusée avec la raison exacte.

Captive ne lit que **la racine du dépôt** : un `Gemfile` ou un `package.json` placé dans un sous-dossier n'est pas vu.

## Rails

Condition : un `Gemfile` à la racine qui contient la gem `rails`.

```ruby
gem "rails", "8.1.0"
```

- Avec une gem d'assets (`propshaft`, `sprockets-rails`, `importmap-rails`, `jsbundling-rails`, `cssbundling-rails`, `tailwindcss-rails`…), l'application est construite avec ses assets frontend.
- Sans gem d'assets, elle est construite comme une API.
- `gem "pg"` provisionne une base Postgres, `gem "redis"` ou `gem "sidekiq"` un Redis.
- Les bibliothèques système exigées par certaines gems sont installées dans l'image : `ruby-vips` (libvips), `mini_magick` et `rmagick` (imagemagick), `sqlite3`, et `ethon` (libcurl), y compris quand la gem n'arrive qu'en dépendance d'une autre via le `Gemfile.lock`. Pour une bibliothèque non détectée, listez le paquet Debian dans un `Aptfile` à la racine.

Si un `Gemfile` est présent, c'est toujours lui qui décide : un dépôt avec un `Gemfile` sans Rails est refusé, même s'il a aussi un `package.json`.

## Node

Condition : un `package.json` à la racine, sans dépendance `expo`, avec un script **`start`** ou **`build`**.

### Application web (SPA : Vite, React, Vue…)

Votre application est buildée une fois, puis servie en fichiers statiques. Aucun process Node ne tourne en production.

```json
{
  "scripts": {
    "dev": "vite",
    "build": "vite build"
  },
  "devDependencies": {
    "vite": "7.1.0"
  }
}
```

- Le script `build` doit produire le dossier **`dist/`** à la racine. C'est le comportement par défaut de Vite ; si vous avez changé `build.outDir`, remettez `dist`.
- Toutes les routes inconnues renvoient `index.html` : le routage côté client (React Router, Vue Router…) fonctionne sans configuration.
- Les variables d'environnement sont injectées **au moment du build** (par exemple `VITE_SUPABASE_URL`). Après en avoir modifié une, redéployez.

### Serveur Node (Next.js, Nuxt, SvelteKit, Remix)

Si votre `package.json` dépend de `next`, `nuxt`, `@sveltejs/kit` ou d'un paquet `@remix-run/…`, Captive lance un vrai serveur Node avec votre script `start`.

```json
{
  "scripts": {
    "build": "next build",
    "start": "next start"
  },
  "dependencies": {
    "next": "15.0.0"
  }
}
```

### Services

- `pg` ou `postgres` provisionne une base Postgres.
- `redis` ou `ioredis` provisionne un Redis.
- `@supabase/supabase-js` ou `@supabase/ssr` provisionne un backend Supabase.
- Une ligne `worker: <commande>` dans un `Procfile` lance un worker.


### Variables exposées au navigateur

Une variable n'arrive dans le code du navigateur que si elle porte le préfixe de votre bundler. Captive le déduit de vos dépendances :

| Dépendance | Préfixe |
| --- | --- |
| `expo` | `EXPO_PUBLIC_` |
| `next` | `NEXT_PUBLIC_` |
| `vite` | `VITE_` |

Si plusieurs sont présentes, c'est le premier de la liste qui l'emporte (`vite` est souvent là pour les tests seulement).

Avec un backend Supabase, Captive pose l'URL et la clé publique sous ce préfixe, avec les deux noms de clé en usage : `VITE_SUPABASE_URL`, `VITE_SUPABASE_ANON_KEY` et `VITE_SUPABASE_PUBLISHABLE_KEY` pour une application Vite, par exemple. Côté serveur, les mêmes valeurs sont disponibles sans préfixe : `SUPABASE_URL` et `SUPABASE_ANON_KEY`.

Ces variables sont lues **au build** : après en avoir changé une, redéployez.

## Expo

Condition : un `package.json` à la racine avec la dépendance `expo` (dans `dependencies` ou `devDependencies`). Aucun script n'est exigé.

```json
{
  "dependencies": {
    "expo": "54.0.0"
  }
}
```

## Ma création est refusée

| Message | Cause | Que faire |
| --- | --- | --- |
| Aucun Gemfile ni package.json à la racine du dépôt. | Pas de fichier de dépendances à la racine. | Vérifiez que l'application est bien à la racine du dépôt, pas dans un sous-dossier (`app/`, `frontend/`…). Les monorepos ne sont pas pris en charge. |
| Gemfile trouvé, mais sans la gem rails. | Application Ruby non Rails (Sinatra, Hanami…), ou `Gemfile` d'outillage dans un projet JavaScript. | Seul Rails est pris en charge côté Ruby. Si le `Gemfile` ne sert qu'à de l'outillage, retirez-le du dépôt. |
| package.json trouvé, mais sans dépendance expo ni script start ou build. | Captive ne sait pas comment construire l'application. | Ajoutez un script `build` (application web) ou `start` (serveur), comme dans les exemples ci-dessus. |

Si votre stack n'est pas listée ici, contactez l'équipe Captive.
