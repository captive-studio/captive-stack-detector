# ADR 0003 — La doc publique des stacks vit dans la gem

## Statut

Accepté

## Contexte

Quand la détection refuse un dépôt, l'utilisateur doit savoir pourquoi et comment le rendre déployable. Une page de documentation publique explique les stacks supportées, la règle exacte de chacune et la marche à suivre pour chaque raison de refus (`UnsupportedReason`).

Cette page a d'abord été écrite dans captive-dashboard. Mais les règles qu'elle décrit sont celles de la gem : chaque changement de détection (nouveau script accepté, nouveau framework SSR, nouveau service) la rendait fausse sans que rien ne le signale dans le dépôt qui faisait le changement.

## Décision

La page vit dans la gem, en `docs/stacks.md`, livrée dans le paquet (`spec.files`) et exposée par `CaptiveStackDetector::DOC_PATH`. captive-dashboard la lit depuis la gem installée et l'affiche sur `/docs/platform/stacks`, comme ses autres pages de doc.

**Tout changement de la détection qui modifie ce qu'un utilisateur voit (stack acceptée ou refusée, sous-type, services provisionnés, raison de refus) met à jour `docs/stacks.md` dans la même PR.**

## Raisons

- La règle et sa doc changent ensemble, dans le même dépôt, sous la même revue.
- La doc affichée suit exactement la version de la gem installée par le dashboard : pas de décalage entre ce qui est détecté et ce qui est expliqué.
- Un dépôt de doc séparé ou une page dans le dashboard ont été écartés : ils dépendent d'une discipline entre deux dépôts que rien ne vérifie.

## Conséquences

- `docs/stacks.md` est écrite pour les utilisateurs du dashboard (en français, sans détail d'implémentation) ; les règles internes restent dans le README et `CONTEXT.md`.
- Un spec vérifie que le fichier est livré dans la gem et qu'il couvre chaque message de refus.
- Corriger une coquille dans la doc demande une release de la gem et sa montée dans le dashboard.
