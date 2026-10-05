# Contrat frontend — abonnements Premium

Ce document décrit le contrat Django consommé par Flutter. Les prix, la devise
effective et les droits proviennent toujours du serveur ; l'application ne les
recalcule pas pour initier un paiement.

## Navigation

- Route Flutter canonique : `/premium`.
- Ancienne route `/subscription` : redirection de compatibilité vers
  `/premium`.
- Toutes les entrées Premium (Découverte, notifications, likes reçus, Profil,
  filtres, chat et ressources) utilisent la route canonique.

## Profil et devise

`GET/PATCH /api/v1/user-profiles/me/` expose :

```json
{
  "preferred_currency": "AUTO",
  "effective_currency": "XAF"
}
```

`preferred_currency` accepte `AUTO`, `XAF` ou `EUR`. `AUTO` applique `XAF`
pour un pays CEMAC et `EUR` ailleurs. Flutter envoie uniquement la préférence ;
le backend détermine la devise effective.

## Catalogue

`GET /api/v1/subscriptions/plans/` exige une authentification et retourne une
liste DRF paginée. Seuls les identifiants suivants sont commercialisables :

- `hivmeet_monthly` : 7,99 EUR par mois ;
- `hivmeet_annual` : 57,99 EUR par an, équivalent à 4,83 EUR par mois,
  soit 40 % d'économie par rapport à douze mensualités.

Extrait de réponse :

```json
{
  "count": 2,
  "results": [
    {
      "plan_id": "hivmeet_annual",
      "price": "38038",
      "currency": "XAF",
      "base_price": "57.99",
      "base_currency": "EUR",
      "billing_interval": "year",
      "monthly_equivalent": "3170",
      "savings_percentage": 40,
      "most_popular": true,
      "recommended": true,
      "features": {
        "unlimited_likes": true,
        "can_see_likers": true,
        "can_rewind": true,
        "daily_rewinds_count": 5,
        "daily_super_likes_count": 5
      }
    }
  ]
}
```

Le prix XAF est arrondi au franc entier par le backend. Flutter affiche le
prix et `monthly_equivalent` reçus, ainsi que `savings_percentage`.

## Capacité de paiement

Avant d'afficher le champ Mobile Money, Flutter appelle
`GET /api/v1/subscriptions/payment-capabilities/` :

```json
{
  "provider": "mycoolpay",
  "available": true,
  "callback_verification_available": false,
  "automatic_return_available": false,
  "confirmation_mode": "polling_only",
  "enabled_currencies": ["EUR", "XAF"],
  "default_currency": "EUR",
  "effective_currency": "XAF"
}
```

Si `available` vaut `false`, le numéro et la validation sont masqués et un
message localisé explique l'indisponibilité. En mode `polling_only`, le Paylink
reste achetable : Flutter demande à l'utilisateur de revenir dans l'application
et vérifie alors le statut authentifié auprès du backend. Le mode
`webhook_and_polling` n'est annoncé que lorsque la clé privée, les IP autorisées
et les quatre URL HTTPS exactes sont configurées. Aucune clé fournisseur n'est
présente dans cette réponse.

## Achat et statut

`POST /api/v1/subscriptions/purchase/` reçoit :

```json
{
  "plan_id": "hivmeet_monthly",
  "phone_number": "+237699009900",
  "language": "fr"
}
```

Le montant et la devise sont recalculés par Django. Le statut de confiance est
`GET /api/v1/subscriptions/payments/{payment_id}/`; un retour navigateur ne
débloque jamais Premium à lui seul. La persistance, le deep link, le polling et
l'idempotence côté Flutter relèvent de la phase 3.

## Erreurs

Le backend renvoie l'enveloppe stable :

```json
{
  "error": "payment_not_configured",
  "message": "Payment is temporarily unavailable",
  "details": null,
  "status_code": 503
}
```

Flutter n'affiche jamais `message` ni `details` directement. `error` est mappé
vers un texte FR/EN contrôlé ; tout code inconnu produit un message générique.

## Rewind

Le rewind décrit ici est l'annulation immédiate du dernier swipe depuis
Découverte. Il est réservé aux comptes Premium, limité à 5 utilisations par
jour et ne restitue pas le swipe consommé. La révocation depuis l'historique
reste une fonctionnalité distincte et gratuite.
