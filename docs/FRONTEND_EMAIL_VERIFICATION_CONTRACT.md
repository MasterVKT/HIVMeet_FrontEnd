# Contrat frontend - verification e-mail Firebase

## Inscription

Le backend cree les comptes Django et Firebase de maniere coordonnee par
`POST /api/v1/auth/register/`. Sa reponse `201` contient
`verification_required: true`; elle confirme seulement la creation du compte,
jamais la livraison d'un e-mail et jamais un JWT Django.

Apres l'inscription, le client ouvre une session Firebase limitee a l'attente,
choisit la langue Firebase et appelle `sendEmailVerification()`. Un echec de
cet appel est affiche comme un echec d'envoi distinct et l'ecran d'attente
permet un nouvel essai apres temporisation.

## Passage a la session applicative

Au retour au premier plan ou sur action explicite, le client appelle
`reload()`. Il demande un ID token Firebase frais et appelle
`POST /api/v1/auth/firebase-exchange/` seulement lorsque
`FirebaseAuth.currentUser.emailVerified` vaut `true`. Aucun JWT Django n'est
stocke, restaure ou utilise avant cette preuve.

Le code `email_not_verified` est un `403` commun a l'echange Firebase, la
connexion, le rafraichissement de JWT, les routes protegees et les WebSockets.
Le client le traduit localement, efface les JWT Django et affiche l'ecran
d'attente. L'ancien endpoint Django `GET /auth/verify-email/{token}` est
reserve aux liens valides emis avant ce changement; aucun nouveau lien Django
ne doit etre emis.
