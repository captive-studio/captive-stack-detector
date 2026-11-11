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

### Serveur Node (Next.js, Nuxt, SvelteKit, Remix, Astro, TanStack Start)

Si votre `package.json` dépend de `next`, `nuxt`, `@sveltejs/kit`, `@astrojs/node`, `@tanstack/react-start`, `@tanstack/solid-start` ou d'un paquet `@remix-run/…`, Captive lance un vrai serveur Node avec votre script `start`.

Pour Astro, utilisez l'adaptateur `@astrojs/node` en mode `standalone`, avec `output: 'server'`. Le script `start` doit lancer le serveur construit (par exemple `node ./dist/server/entry.mjs`) sur `0.0.0.0`, au port fourni par `PORT`. Les dépendances et les devDependencies sont prises en compte. Astro seul, sans adaptateur Node, reste servi en fichiers statiques.

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


### Variables à renseigner

La détection Node recherche les lectures à clé littérale `process.env.MA_CLE`,
`process.env["MA_CLE"]`, `import.meta.env.MA_CLE` et `import.meta.env["MA_CLE"]`
dans les sources JavaScript, TypeScript, JSX, TSX, Astro, Vue et Svelte, y compris les
fichiers de configuration à la racine. Les imports nommés de `astro:env/client` et
`astro:env/server` sont également reconnus.

Les modèles `.env.example`, `.env.sample` et `.env.template` à la racine déclarent aussi
des noms de variables à renseigner. **Leurs valeurs ne sont jamais reprises** : chaque nom
est signalé avec la valeur `placeholder`. Les fichiers `.env`, `.env.local` et les autres
fichiers d'environnement réels ne sont pas lus.

Les commentaires, chaînes d'exemple, dépendances, sorties de build, scripts d'outillage
(`scripts/`, `bin/`), documentation, exemples, tests, stories et
déclarations TypeScript sont ignorés. Les constantes intégrées de Vite et les variables
`NODE_ENV`, `NODE_OPTIONS`, `HOST` et `PORT` ne sont pas demandées. Une lecture avec une
valeur de repli littérale (`?? "local"`, `|| "local"`, nombre ou booléen) est facultative ;
une lecture sans repli ailleurs, ou sa déclaration dans un modèle, demande toujours la clé.

L'analyse est statique : les clés calculées, la déstructuration et les appels indirects
(comme `getSecret(nom)`) ne sont pas déduits. Déclarez ces clés dans un modèle si nécessaire.
La même analyse est utilisée sur les dépôts locaux et GitHub.

### Variables exposées au navigateur

Une variable n'arrive dans le code du navigateur que si elle porte le préfixe de votre bundler. Captive le déduit de vos dépendances :

| Dépendance | Préfixe |
| --- | --- |
| `expo` | `EXPO_PUBLIC_` |
| `next` | `NEXT_PUBLIC_` |
| `astro` | `PUBLIC_` |
| `vite` | `VITE_` |

Si plusieurs sont présentes, c'est le premier de la liste qui l'emporte (`vite` est souvent là pour les tests seulement).

Avec un backend Supabase, Captive pose l'URL et la clé publique sous ce préfixe, avec les deux noms de clé en usage : `VITE_SUPABASE_URL`, `VITE_SUPABASE_ANON_KEY` et `VITE_SUPABASE_PUBLISHABLE_KEY` pour une application Vite, par exemple. Côté serveur, les mêmes valeurs sont disponibles sans préfixe : `SUPABASE_URL` et `SUPABASE_ANON_KEY`.

Ces variables sont lues **au build** : après en avoir changé une, redéployez.

### Site statique sans build

Condition : pas de `Gemfile` à la racine, mais un `public/index.html` ou un `index.html` à la racine. Un `package.json` est accepté s'il ne sert qu'à l'outillage (Supabase CLI, prettier…) : sans dépendance `expo` ni script `start` ou `build`. Rien n'est installé ni buildé : vos fichiers sont servis tels quels.

- Si `public/` existe, seul ce dossier est servi.
- Sinon la racine est servie, limitée aux fichiers web (HTML, JavaScript, CSS, JSON, images, polices, manifeste, texte). Les dossiers cachés (`.git/`, `.github/`), `supabase/`, vos scripts SQL ou votre documentation ne sont jamais publiés.
- Un dossier `supabase/` avec son `config.toml` provisionne un backend Supabase et sa base Postgres.
- Faute de build, aucune variable n'est injectée : votre code lit directement l'adresse de l'API, par exemple `location.origin`.

## Options Supabase recommandées

Avec un backend Supabase (application Node ou site statique), Captive lit votre code et vous recommande les options de l'add-on dont il a besoin, chacune avec sa raison (par exemple « votre code appelle signUp »). Une recommandation ne s'active pas seule : vous la retrouvez dans le dashboard au moment de la création.

| Option | Recommandée quand |
| --- | --- |
| `smtp` | votre JavaScript ou TypeScript appelle `signUp`, `resetPasswordForEmail`, `signInWithOtp`, `inviteUserByEmail` ou `updateUser({ email })` : Supabase doit envoyer un email. Une connexion par `signInWithPassword` ou la double authentification (`auth.mfa`) n'en envoie pas. |
| `realtime` | votre code s'abonne à un canal (`.channel(`) ou aux changements de la base (`postgres_changes`). |
| `pg_cron` | un fichier `.sql` du dépôt (dont `supabase/migrations/` et `db/`) appelle `cron.schedule`, ou `net.http_` (pg_net est livré avec pg_cron). |
| `vault` | un fichier `.sql` utilise le coffre Supabase (`vault.create_secret`, `vault.decrypted_secrets`…). |

Les dépendances (`node_modules/`), sorties de build, tests et fichiers vendored sont ignorés, comme pour les variables. L'analyse est statique : un appel construit dynamiquement n'est pas vu ; activez alors l'option vous-même.

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
| Aucun Gemfile ni package.json à la racine du dépôt. | Pas de fichier de dépendances ni d'`index.html` à la racine. | Vérifiez que l'application est bien à la racine du dépôt, pas dans un sous-dossier (`app/`, `frontend/`…). Les monorepos ne sont pas pris en charge. |
| Gemfile trouvé, mais sans la gem rails. | Application Ruby non Rails (Sinatra, Hanami…), ou `Gemfile` d'outillage dans un projet JavaScript. | Seul Rails est pris en charge côté Ruby. Si le `Gemfile` ne sert qu'à de l'outillage, retirez-le du dépôt. |
| package.json trouvé, mais sans dépendance expo ni script start ou build. | Captive ne sait pas comment construire l'application, et aucun `index.html` ne permet de la servir telle quelle. | Ajoutez un script `build` (application web) ou `start` (serveur), comme dans les exemples ci-dessus, ou un `index.html` pour un site statique. |

Si votre stack n'est pas listée ici, contactez l'équipe Captive.
