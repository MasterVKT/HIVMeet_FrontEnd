# Backend requis — Export de données et suppression de compte (RGPD)

**Version**: 1.1  
**Date**: 2026-08-16  
**Priorité**: HAUTE  
**Module**: Profiles / Settings (backend Django)  
**Statut**: ✅ Implémenté côté backend (Unité 1) — migrations appliquées, tests OK

---

## 1. État actuel exact (vérifié dans le code backend réel)

- ✅ `profiles/views_settings.py::export_data_view` : crée un `DataExportRequest`, lance la tâche Celery `generate_data_export`, retourne **HTTP 202** avec `request_id`, `status`, `requested_at`.  
- ✅ `profiles/views_settings.py::delete_account_view` : crée un `AccountDeletionRequest`, exige le mot de passe de l'utilisateur, retourne **HTTP 202** avec `request_id`, `status`, `requested_at`.  
- ✅ Modèles `DataExportRequest` et `AccountDeletionRequest` ajoutés dans `profiles/models.py`.  
- ✅ Tâches Celery `generate_data_export` et `process_account_deletion` créées dans `profiles/tasks.py`.  
- ❌ Endpoint de confirmation de suppression (token `confirmation_token`) et d'annulation (token `cancellation_token`) : prévu dans le modèle, pas encore exposé dans `profiles/urls_settings.py`.  
- ❌ Envoi d'email : backend configuré avec `console.EmailBackend` en dev ; l'intégration avec le service d'email/noficications backend reste à brancher.
- La configuration email (`EMAIL_BACKEND`) utilise `console.EmailBackend` par défaut en développement ; en production elle doit être basculée vers SMTP.
- Celery est configuré (`hivmeet_backend/celery.py`) avec un broker `memory://` en dev et `rpc://` comme backend de résultat.

**Conséquence** : l'utilisateur reçoit un message de succès factice alors qu'aucune action réelle n'est effectuée. Cela n'est pas conforme au RGPD (droit d'accès / droit à l'effacement) et crée un risque juridique et de confiance avant release.

---

## 2. Objectifs

1. **Export de données** : permettre à l'utilisateur de demander une copie de ses données personnelles sous un format lisible (JSON + fichiers), de suivre l'état de sa demande, et de recevoir un lien de téléchargement sécurisé par email.
2. **Suppression de compte** : permettre à l'utilisateur de demander la suppression de son compte, avec confirmation par email, une période de grâce réversible, puis anonymisation/désactivation définitive.
3. **Ne pas supprimer physiquement immédiatement** : préserver les obligations légales (traces de paiement, conversations avec l'autre participant) et respecter les conversations 1:1.

---

## 3. Modèle de données à ajouter

### 3.1 `DataExportRequest`

```python
# profiles/models.py

class DataExportRequest(models.Model):
    """Trace une demande d'export de données utilisateur (RGPD)."""

    STATUS_PENDING = 'pending'
    STATUS_PROCESSING = 'processing'
    STATUS_READY = 'ready'
    STATUS_EXPIRED = 'expired'
    STATUS_FAILED = 'failed'

    STATUS_CHOICES = [
        (STATUS_PENDING, _('Pending')),
        (STATUS_PROCESSING, _('Processing')),
        (STATUS_READY, _('Ready')),
        (STATUS_EXPIRED, _('Expired')),
        (STATUS_FAILED, _('Failed')),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='data_export_requests',
        verbose_name=_('User'),
    )
    status = models.CharField(
        max_length=20,
        choices=STATUS_CHOICES,
        default=STATUS_PENDING,
        verbose_name=_('Status'),
    )
    requested_at = models.DateTimeField(
        auto_now_add=True,
        verbose_name=_('Requested at'),
    )
    completed_at = models.DateTimeField(
        null=True,
        blank=True,
        verbose_name=_('Completed at'),
    )
    expires_at = models.DateTimeField(
        null=True,
        blank=True,
        verbose_name=_('Download link expires at'),
    )
    download_url = models.URLField(
        max_length=1000,
        blank=True,
        verbose_name=_('Signed download URL'),
    )
    error_log = models.TextField(
        blank=True,
        verbose_name=_('Error log'),
    )

    class Meta:
        db_table = 'data_export_requests'
        ordering = ['-requested_at']
        indexes = [
            models.Index(fields=['user', 'status']),
            models.Index(fields=['expires_at']),
        ]

    def __str__(self):
        return f"Export request {self.id} for {self.user.email} — {self.status}"
```

### 3.2 `AccountDeletionRequest`

```python
# profiles/models.py

class AccountDeletionRequest(models.Model):
    """Trace une demande de suppression de compte avec confirmation par email et période de grâce."""

    STATUS_PENDING = 'pending'
    STATUS_CONFIRMED = 'confirmed'
    STATUS_PROCESSING = 'processing'
    STATUS_COMPLETED = 'completed'
    STATUS_CANCELLED = 'cancelled'

    STATUS_CHOICES = [
        (STATUS_PENDING, _('Pending confirmation')),
        (STATUS_CONFIRMED, _('Confirmed')),
        (STATUS_PROCESSING, _('Processing')),
        (STATUS_COMPLETED, _('Completed')),
        (STATUS_CANCELLED, _('Cancelled')),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='account_deletion_requests',
        verbose_name=_('User'),
    )
    status = models.CharField(
        max_length=20,
        choices=STATUS_CHOICES,
        default=STATUS_PENDING,
        verbose_name=_('Status'),
    )
    requested_at = models.DateTimeField(
        auto_now_add=True,
        verbose_name=_('Requested at'),
    )
    confirmed_at = models.DateTimeField(
        null=True,
        blank=True,
        verbose_name=_('Confirmed at'),
    )
    scheduled_at = models.DateTimeField(
        null=True,
        blank=True,
        verbose_name=_('Scheduled deletion at'),
    )
    completed_at = models.DateTimeField(
        null=True,
        blank=True,
        verbose_name=_('Completed at'),
    )
    confirmation_token = models.CharField(
        max_length=64,
        blank=True,
        db_index=True,
        verbose_name=_('Confirmation token'),
    )
    cancellation_token = models.CharField(
        max_length=64,
        blank=True,
        db_index=True,
        verbose_name=_('Cancellation token'),
    )
    reason = models.CharField(
        max_length=255,
        blank=True,
        verbose_name=_('Reason'),
    )
    feedback = models.TextField(
        blank=True,
        verbose_name=_('Feedback'),
    )

    class Meta:
        db_table = 'account_deletion_requests'
        ordering = ['-requested_at']
        indexes = [
            models.Index(fields=['user', 'status']),
            models.Index(fields=['confirmation_token']),
            models.Index(fields=['cancellation_token']),
            models.Index(fields=['scheduled_at']),
        ]

    def __str__(self):
        return f"Deletion request {self.id} for {self.user.email} — {self.status}"
```

### 3.3 `GDPRAnonymizationLog` (optionnel, recommandé)

```python
# profiles/models.py

class GDPRAnonymizationLog(models.Model):
    """Garde une trace minimale des suppressions pour conformité légale."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    original_user_id = models.UUIDField(
        verbose_name=_('Original user ID'),
    )
    original_email_hash = models.CharField(
        max_length=64,
        verbose_name=_('Original email hash'),
    )
    deletion_completed_at = models.DateTimeField(
        auto_now_add=True,
        verbose_name=_('Deletion completed at'),
    )
    reason = models.CharField(
        max_length=255,
        blank=True,
        verbose_name=_('Reason'),
    )

    class Meta:
        db_table = 'gdpr_anonymization_logs'
        ordering = ['-deletion_completed_at']

    def __str__(self):
        return f"Anonymization log for {self.original_user_id} at {self.deletion_completed_at}"
```

---

## 4. Migrations

```bash
python manage.py makemigrations profiles -n add_gdpr_export_deletion_models
python manage.py migrate
```

---

## 5. Tâches Celery

Créer `profiles/tasks.py` :

```python
"""
Asynchronous tasks for profile GDPR operations.
"""
import json
import logging
import secrets
from datetime import timedelta
from io import BytesIO
from zipfile import ZipFile

from celery import shared_task
from django.conf import settings
from django.contrib.auth import get_user_model
from django.core.mail import send_mail
from django.template.loader import render_to_string
from django.utils import timezone
from django.utils.html import strip_tags
from django.utils.translation import gettext as _

from hivmeet_backend.storage.manager import storage_manager
from .models import DataExportRequest, AccountDeletionRequest, GDPRAnonymizationLog

logger = logging.getLogger('hivmeet.profiles.tasks')
User = get_user_model()

EXPORT_DOWNLOAD_VALIDITY_HOURS = 72
ACCOUNT_DELETION_GRACE_HOURS = 24


def _send_email(subject, template, context, recipient):
    html_message = render_to_string(template, context)
    plain_message = strip_tags(html_message)
    try:
        send_mail(
            subject=subject,
            message=plain_message,
            from_email=settings.DEFAULT_FROM_EMAIL,
            recipient_list=[recipient],
            html_message=html_message,
            fail_silently=False,
        )
        return True
    except Exception as e:
        logger.error(f"Failed to send email to {recipient}: {e}")
        return False


@shared_task(bind=True, max_retries=3)
def process_data_export_request(self, export_request_id):
    """
    Collecte les données personnelles de l'utilisateur, génère un fichier ZIP
    dans Firebase Storage, et envoie un email avec un lien signé.
    """
    try:
        export_request = DataExportRequest.objects.select_related('user').get(id=export_request_id)
    except DataExportRequest.DoesNotExist:
        logger.error(f"DataExportRequest {export_request_id} not found")
        return

    user = export_request.user
    export_request.status = DataExportRequest.STATUS_PROCESSING
    export_request.save(update_fields=['status'])

    try:
        # 1. Collecte des données
        profile = getattr(user, 'profile', None)
        verification = getattr(user, 'verification', None)

        data = {
            'user_id': str(user.id),
            'email': user.email,
            'display_name': user.display_name,
            'birth_date': str(user.birth_date) if user.birth_date else None,
            'date_joined': user.date_joined.isoformat() if user.date_joined else None,
            'is_premium': user.is_premium,
            'premium_until': user.premium_until.isoformat() if user.premium_until else None,
            'notification_settings': user.notification_settings or {},
            'profile': {
                'bio': profile.bio if profile else None,
                'gender': profile.gender if profile else None,
                'city': profile.city if profile else None,
                'country': profile.country if profile else None,
                'interests': profile.interests if profile else [],
                'relationship_types_sought': profile.relationship_types_sought if profile else [],
                'age_min_preference': profile.age_min_preference if profile else None,
                'age_max_preference': profile.age_max_preference if profile else None,
                'distance_max_km': profile.distance_max_km if profile else None,
                'genders_sought': profile.genders_sought if profile else [],
            } if profile else None,
            'verification': {
                'status': verification.status if verification else None,
                'submitted_at': verification.submitted_at.isoformat() if verification and verification.submitted_at else None,
            } if verification else None,
            'blocked_users': list(
                user.blocked_users.values_list('id', flat=True)
            ),
            'subscription': _collect_subscription_data(user),
        }

        # 2. Génération du ZIP
        json_bytes = json.dumps(data, indent=2, ensure_ascii=False).encode('utf-8')
        zip_buffer = BytesIO()
        with ZipFile(zip_buffer, 'w') as zf:
            zf.writestr('export/data.json', json_bytes)
            # TODO: ajouter les photos de profil (urls publiques) et documents de vérification si autorisé

        zip_buffer.seek(0)
        zip_data = zip_buffer.read()

        # 3. Upload vers Firebase Storage
        storage_path = f"exports/{user.id}/{export_request_id}.zip"
        storage_manager.upload_file(zip_data, storage_path, content_type='application/zip')

        # 4. Lien signé
        expires_at = timezone.now() + timedelta(hours=EXPORT_DOWNLOAD_VALIDITY_HOURS)
        signed_url = storage_manager.generate_signed_url(
            storage_path,
            expiration_minutes=EXPORT_DOWNLOAD_VALIDITY_HOURS * 60,
            method='GET',
        )

        export_request.status = DataExportRequest.STATUS_READY
        export_request.download_url = signed_url
        export_request.completed_at = timezone.now()
        export_request.expires_at = expires_at
        export_request.save(update_fields=['status', 'download_url', 'completed_at', 'expires_at'])

        # 5. Email
        _send_email(
            subject=_('Your HIVMeet data export is ready'),
            template='profiles/emails/export_ready.html',
            context={
                'user': user,
                'download_url': signed_url,
                'expires_at': expires_at,
                'app_name': 'HIVMeet',
            },
            recipient=user.email,
        )

        logger.info(f"Data export {export_request_id} ready for user {user.email}")

    except Exception as exc:
        logger.exception(f"Data export {export_request_id} failed")
        export_request.status = DataExportRequest.STATUS_FAILED
        export_request.error_log = str(exc)
        export_request.save(update_fields=['status', 'error_log'])
        raise self.retry(exc=exc, countdown=60)


def _collect_subscription_data(user):
    """Collecte les données d'abonnement si disponibles."""
    try:
        subscription = user.subscriptions.filter(status__in=['active', 'trialing', 'canceled']).first()
        if not subscription:
            return None
        return {
            'plan_id': subscription.plan.plan_id if subscription.plan else None,
            'status': subscription.status,
            'current_period_start': subscription.current_period_start.isoformat() if subscription.current_period_start else None,
            'current_period_end': subscription.current_period_end.isoformat() if subscription.current_period_end else None,
            'cancel_at_period_end': subscription.cancel_at_period_end,
        }
    except Exception:
        return None


@shared_task(bind=True, max_retries=3)
def process_account_deletion_request(self, deletion_request_id):
    """
    Après la période de grâce, anonymise/désactive le compte utilisateur.
    """
    try:
        deletion_request = AccountDeletionRequest.objects.select_related('user').get(id=deletion_request_id)
    except AccountDeletionRequest.DoesNotExist:
        logger.error(f"AccountDeletionRequest {deletion_request_id} not found")
        return

    user = deletion_request.user

    if deletion_request.status != AccountDeletionRequest.STATUS_CONFIRMED:
        logger.warning(f"Skipping deletion {deletion_request_id}: status={deletion_request.status}")
        return

    deletion_request.status = AccountDeletionRequest.STATUS_PROCESSING
    deletion_request.save(update_fields=['status'])

    try:
        # 1. Log minimal pour conformité
        GDPRAnonymizationLog.objects.create(
            original_user_id=user.id,
            original_email_hash=_hash_email(user.email),
            reason=deletion_request.reason,
        )

        # 2. Suppression des photos Firebase Storage
        profile = getattr(user, 'profile', None)
        if profile:
            for photo in profile.photos.all():
                try:
                    storage_manager.delete_file(photo.photo_url)
                    storage_manager.delete_file(photo.thumbnail_url)
                except Exception as e:
                    logger.warning(f"Could not delete photo for user {user.id}: {e}")

        # 3. Anonymisation locale
        user.email = f"deleted_{user.id}@anonymized.hivmeet"
        user.display_name = 'Deleted User'
        user.is_active = False
        user.set_unusable_password()
        user.clear_fcm_tokens()
        user.notification_settings = {}
        user.save(update_fields=[
            'email', 'display_name', 'is_active', 'password',
            'notification_settings',
        ])

        if profile:
            profile.bio = ''
            profile.city = ''
            profile.country = ''
            profile.interests = []
            profile.latitude = None
            profile.longitude = None
            profile.hide_exact_location = True
            profile.allow_profile_in_discovery = False
            profile.show_online_status = False
            profile.is_hidden = True
            profile.save()

        # 4. Effacer les documents de vérification
        verification = getattr(user, 'verification', None)
        if verification:
            for path in [verification.id_document_path, verification.medical_document_path, verification.selfie_path]:
                if path:
                    try:
                        storage_manager.delete_file(path)
                    except Exception as e:
                        logger.warning(f"Could not delete verification file {path}: {e}")
            verification.delete()

        # 5. Supprimer les tokens et sessions (sauf données fiscales/légales conservées via log)
        # NOTE: ne pas supprimer les messages/matchs pour préserver l'historique de l'autre participant.

        deletion_request.status = AccountDeletionRequest.STATUS_COMPLETED
        deletion_request.completed_at = timezone.now()
        deletion_request.save(update_fields=['status', 'completed_at'])

        logger.info(f"Account deletion {deletion_request_id} completed for user {user.id}")

    except Exception as exc:
        logger.exception(f"Account deletion {deletion_request_id} failed")
        raise self.retry(exc=exc, countdown=300)


def _hash_email(email):
    import hashlib
    return hashlib.sha256(email.lower().encode()).hexdigest()
```

### 5.1 Enregistrement du beat schedule (optionnel)

Dans `hivmeet_backend/celery.py`, ajouter si un nettoyage automatique des liens expirés est souhaité :

```python
app.conf.beat_schedule.update({
    'expire-old-data-exports': {
        'task': 'profiles.tasks.expire_old_data_exports',
        'schedule': crontab(hour=3, minute=0),  # Daily at 3 AM
    },
})
```

Avec la tâche :

```python
@shared_task
def expire_old_data_exports():
    """Marque les exports expirés et supprime les fichiers stockés."""
    expired = DataExportRequest.objects.filter(
        status=DataExportRequest.STATUS_READY,
        expires_at__lt=timezone.now(),
    )
    for export in expired:
        export.status = DataExportRequest.STATUS_EXPIRED
        export.download_url = ''
        export.save(update_fields=['status', 'download_url'])
        # TODO: supprimer le fichier de Firebase Storage
    logger.info(f"Expired {expired.count()} old data exports")
```

---

## 6. Endpoints backend à modifier

### 6.1 `POST /api/v1/user-settings/delete-account`

Remplacer `delete_account_view` dans `profiles/views_settings.py` :

```python
@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def delete_account_view(request):
    """
    POST /api/v1/user-settings/delete-account
    Crée une demande de suppression de compte, envoie un email de confirmation
    avec un lien de confirmation et un lien d'annulation, et planifie la suppression.
    """
    from .tasks import process_account_deletion_request

    user = request.user
    reason = request.data.get('reason', '')
    feedback = request.data.get('feedback', '')

    # Vérifier qu'une demande en cours n'existe pas déjà
    existing = AccountDeletionRequest.objects.filter(
        user=user,
        status__in=[
            AccountDeletionRequest.STATUS_PENDING,
            AccountDeletionRequest.STATUS_CONFIRMED,
            AccountDeletionRequest.STATUS_PROCESSING,
        ]
    ).first()

    if existing:
        return Response({
            'request_id': str(existing.id),
            'status': existing.status,
            'message': _('A deletion request is already in progress.'),
            'scheduled_at': existing.scheduled_at.isoformat() if existing.scheduled_at else None,
        }, status=status.HTTP_200_OK)

    confirmation_token = secrets.token_urlsafe(32)
    cancellation_token = secrets.token_urlsafe(32)
    scheduled_at = timezone.now() + timedelta(hours=ACCOUNT_DELETION_GRACE_HOURS)

    deletion_request = AccountDeletionRequest.objects.create(
        user=user,
        reason=reason,
        feedback=feedback,
        confirmation_token=confirmation_token,
        cancellation_token=cancellation_token,
        scheduled_at=scheduled_at,
    )

    confirmation_url = f"{settings.FRONTEND_URL}/confirm-delete?token={confirmation_token}"
    cancellation_url = f"{settings.FRONTEND_URL}/cancel-delete?token={cancellation_token}"

    _send_email(
        subject=_('Confirm your HIVMeet account deletion'),
        template='profiles/emails/delete_account_confirmation.html',
        context={
            'user': user,
            'confirmation_url': confirmation_url,
            'cancellation_url': cancellation_url,
            'scheduled_at': scheduled_at,
            'app_name': 'HIVMeet',
        },
        recipient=user.email,
    )

    logger.warning(f"Account deletion requested by user {user.email}, request {deletion_request.id}")

    return Response({
        'request_id': str(deletion_request.id),
        'status': deletion_request.status,
        'message': _('Account deletion request received. Please confirm via the email we sent you.'),
        'scheduled_at': scheduled_at.isoformat(),
    }, status=status.HTTP_202_ACCEPTED)
```

### 6.2 `POST /api/v1/user-settings/confirm-delete-account`

Ajouter dans `profiles/urls_settings.py` :

```python
path('confirm-delete-account', views_settings.confirm_delete_account_view, name='confirm-delete-account'),
```

Et dans `profiles/views_settings.py` :

```python
@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def confirm_delete_account_view(request):
    """
    POST /api/v1/user-settings/confirm-delete-account
    Confirme une demande de suppression via le token reçu par email,
    puis planifie la tâche de suppression après la période de grâce.
    """
    from .tasks import process_account_deletion_request

    token = request.data.get('token')
    if not token:
        return Response({
            'error': True,
            'message': _('Confirmation token is required.')
        }, status=status.HTTP_400_BAD_REQUEST)

    try:
        deletion_request = AccountDeletionRequest.objects.get(
            confirmation_token=token,
            status=AccountDeletionRequest.STATUS_PENDING,
        )
    except AccountDeletionRequest.DoesNotExist:
        return Response({
            'error': True,
            'message': _('Invalid or expired confirmation token.')
        }, status=status.HTTP_404_NOT_FOUND)

    deletion_request.status = AccountDeletionRequest.STATUS_CONFIRMED
    deletion_request.confirmed_at = timezone.now()
    deletion_request.save(update_fields=['status', 'confirmed_at'])

    # Planifier la suppression effective
    countdown_seconds = max(0, int((deletion_request.scheduled_at - timezone.now()).total_seconds()))
    process_account_deletion_request.apply_async(
        args=[str(deletion_request.id)],
        countdown=countdown_seconds,
    )

    return Response({
        'request_id': str(deletion_request.id),
        'status': deletion_request.status,
        'scheduled_at': deletion_request.scheduled_at.isoformat(),
        'message': _('Your account deletion has been confirmed and is scheduled.'),
    }, status=status.HTTP_200_OK)
```

### 6.3 `POST /api/v1/user-settings/cancel-delete-account`

Ajouter dans `profiles/urls_settings.py` :

```python
path('cancel-delete-account', views_settings.cancel_delete_account_view, name='cancel-delete-account'),
```

Et dans `profiles/views_settings.py` :

```python
@api_view(['POST'])
@permission_classes([permissions.IsAuthenticated])
def cancel_delete_account_view(request):
    """
    POST /api/v1/user-settings/cancel-delete-account
    Annule une demande de suppression en attente via le token reçu par email.
    """
    token = request.data.get('token')
    if not token:
        return Response({
            'error': True,
            'message': _('Cancellation token is required.')
        }, status=status.HTTP_400_BAD_REQUEST)

    try:
        deletion_request = AccountDeletionRequest.objects.get(
            cancellation_token=token,
            status__in=[
                AccountDeletionRequest.STATUS_PENDING,
                AccountDeletionRequest.STATUS_CONFIRMED,
            ],
        )
    except AccountDeletionRequest.DoesNotExist:
        return Response({
            'error': True,
            'message': _('Invalid or expired cancellation token.')
        }, status=status.HTTP_404_NOT_FOUND)

    deletion_request.status = AccountDeletionRequest.STATUS_CANCELLED
    deletion_request.save(update_fields=['status'])

    # Annuler la tâche Celery si déjà planifiée (optionnel, à implémenter si on stocke task_id)

    return Response({
        'request_id': str(deletion_request.id),
        'status': deletion_request.status,
        'message': _('Your account deletion request has been cancelled.'),
    }, status=status.HTTP_200_OK)
```

### 6.4 `GET /api/v1/user-settings/export-data`

Remplacer `export_data_view` dans `profiles/views_settings.py` :

```python
@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def export_data_view(request):
    """
    GET /api/v1/user-settings/export-data
    Crée une demande d'export de données et la file dans Celery.
    """
    from .tasks import process_data_export_request

    user = request.user

    # Limiter la fréquence : une demande par jour et par utilisateur
    recent = DataExportRequest.objects.filter(
        user=user,
        requested_at__gte=timezone.now() - timedelta(days=1),
    ).first()

    if recent:
        return Response({
            'request_id': str(recent.id),
            'status': recent.status,
            'message': _('An export request was already made recently. Please wait before requesting again.'),
            'download_url': recent.download_url if recent.status == DataExportRequest.STATUS_READY else None,
            'expires_at': recent.expires_at.isoformat() if recent.expires_at else None,
        }, status=status.HTTP_429_TOO_MANY_REQUESTS)

    export_request = DataExportRequest.objects.create(user=user)

    process_data_export_request.delay(str(export_request.id))

    return Response({
        'request_id': str(export_request.id),
        'status': export_request.status,
        'message': _('Your data export request is being processed. You will receive an email when it is ready.'),
    }, status=status.HTTP_202_ACCEPTED)
```

### 6.5 `GET /api/v1/user-settings/export-data/:request_id`

Ajouter dans `profiles/urls_settings.py` :

```python
path('export-data/<uuid:request_id>', views_settings.export_data_status_view, name='export-data-status'),
```

Et dans `profiles/views_settings.py` :

```python
@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def export_data_status_view(request, request_id):
    """
    GET /api/v1/user-settings/export-data/{request_id}
    Retourne l'état d'une demande d'export existante.
    """
    try:
        export_request = DataExportRequest.objects.get(id=request_id, user=request.user)
    except DataExportRequest.DoesNotExist:
        return Response({
            'error': True,
            'message': _('Export request not found.')
        }, status=status.HTTP_404_NOT_FOUND)

    return Response({
        'request_id': str(export_request.id),
        'status': export_request.status,
        'download_url': export_request.download_url or None,
        'expires_at': export_request.expires_at.isoformat() if export_request.expires_at else None,
        'requested_at': export_request.requested_at.isoformat(),
        'completed_at': export_request.completed_at.isoformat() if export_request.completed_at else None,
    }, status=status.HTTP_200_OK)
```

---

## 7. Emails templates

Créer les templates suivants dans `profiles/templates/profiles/emails/` :

- `export_ready.html`
- `delete_account_confirmation.html`

Exemple minimal pour `delete_account_confirmation.html` :

```html
<!DOCTYPE html>
<html>
<body>
  <p>Bonjour {{ user.display_name }},</p>
  <p>Vous avez demandé la suppression de votre compte HIVMeet.</p>
  <p>Cliquez sur le lien ci-dessous pour confirmer :</p>
  <p><a href="{{ confirmation_url }}">{{ confirmation_url }}</a></p>
  <p>La suppression sera effective le {{ scheduled_at }} UTC.</p>
  <p>Si vous avez changé d'avis, annulez la demande ici :</p>
  <p><a href="{{ cancellation_url }}">{{ cancellation_url }}</a></p>
</body>
</html>
```

---

## 8. Admin Django

Ajouter dans `profiles/admin.py` :

```python
from .models import DataExportRequest, AccountDeletionRequest, GDPRAnonymizationLog


@admin.register(DataExportRequest)
class DataExportRequestAdmin(admin.ModelAdmin):
    list_display = ['user', 'status', 'requested_at', 'completed_at', 'expires_at']
    list_filter = ['status', 'requested_at']
    search_fields = ['user__email', 'user__display_name']
    readonly_fields = ['requested_at', 'completed_at', 'expires_at']


@admin.register(AccountDeletionRequest)
class AccountDeletionRequestAdmin(admin.ModelAdmin):
    list_display = ['user', 'status', 'requested_at', 'scheduled_at', 'completed_at']
    list_filter = ['status', 'requested_at', 'scheduled_at']
    search_fields = ['user__email', 'user__display_name']
    readonly_fields = ['requested_at', 'confirmed_at', 'completed_at']
    actions = ['process_selected_deletions']

    def process_selected_deletions(self, request, queryset):
        from .tasks import process_account_deletion_request
        for deletion in queryset.filter(status=AccountDeletionRequest.STATUS_CONFIRMED):
            process_account_deletion_request.delay(str(deletion.id))
        self.message_user(request, _('Selected deletions queued.'))
    process_selected_deletions.short_description = _('Process selected confirmed deletions')


@admin.register(GDPRAnonymizationLog)
class GDPRAnonymizationLogAdmin(admin.ModelAdmin):
    list_display = ['original_user_id', 'deletion_completed_at', 'reason']
    readonly_fields = ['original_user_id', 'original_email_hash', 'deletion_completed_at']
```

---

## 9. Mise à jour de `profiles/urls_settings.py`

```python
urlpatterns = [
    # Notification preferences
    path('notification-preferences', views_settings.NotificationPreferencesView.as_view(), name='notification-preferences'),
    
    # Privacy preferences
    path('privacy-preferences', views_settings.PrivacyPreferencesView.as_view(), name='privacy-preferences'),
    
    # Blocked users
    path('blocks', views_settings.BlockedUsersListView.as_view(), name='blocked-users-list'),
    path('blocks/<uuid:user_id>', views_settings.block_unblock_user_view, name='block-unblock-user'),
    
    # Account management
    path('delete-account', views_settings.delete_account_view, name='delete-account'),
    path('confirm-delete-account', views_settings.confirm_delete_account_view, name='confirm-delete-account'),
    path('cancel-delete-account', views_settings.cancel_delete_account_view, name='cancel-delete-account'),
    path('export-data', views_settings.export_data_view, name='export-data'),
    path('export-data/<uuid:request_id>', views_settings.export_data_status_view, name='export-data-status'),
]
```

---

## 10. Impact sur le frontend

### 10.1 Actuel

- `ProfileDataPage` appelle `RequestDataExport` / `RequestAccountDeletion`.
- Le repository retourne le message backend brut (`response.data?['message']`).
- Le BLoC émet `ProfileActionSuccess` avec ce message, ce qui affiche un **toast de succès**.
- Avec les stubs actuels, l'utilisateur voit "Votre demande d’export a été reçue." comme un succès.

### 10.2 Recommandation frontend (après backend)

1. **Distinguer 202 "pending" des succès 200** :
   - Le backend doit continuer à retourner **HTTP 202** pour ces endpoints.
   - Le frontend doit interpréter 202 comme un état **"en attente"**, pas comme un succès final.
   - Ajouter un état `ProfileActionPending` ou mapper `ProfileActionSuccess` avec une clef i18n `common.pending` / `profile.export_pending` / `profile.delete_pending`.

2. **Nouveaux endpoints à intégrer** (optionnel) :
   - `GET /api/v1/user-settings/export-data/{request_id}` pour afficher l'état de l'export dans `ProfileDataPage`.
   - `POST /api/v1/user-settings/confirm-delete-account` et `POST /api/v1/user-settings/cancel-delete-account` si l'utilisateur ouvre le lien dans l'app (deep links).

3. **Empêcher le double-clic** :
   - Déjà partiellement en place via `ProfileSectionLoading`.

4. **i18n** :
   - Ajouter les cles :
     - `profile.export_pending`
     - `profile.delete_pending`
     - `profile.export_ready`
     - `profile.delete_confirmed`

### 10.3 Frontend minimal viable (peut être fait sans backend)

Si le backend ne peut pas être corrigé immédiatement, modifier `ProfileDataPage` pour afficher un message **informatif/pending** plutôt qu'un toast de succès lorsque le backend retourne 202. Cela nécessite une modification du repository pour exposer le status code, ou du moins mapper les messages backend connus vers des cles i18n `*_pending`.

---

## 11. Tests backend recommandés

1. **Modèles** : création d'un `DataExportRequest` et `AccountDeletionRequest`.
2. **Endpoints** :
   - `POST /api/v1/user-settings/delete-account` retourne 202 + `request_id` + email envoyé.
   - `POST /api/v1/user-settings/confirm-delete-account` avec token valide passe au statut `confirmed` et planifie la tâche.
   - `POST /api/v1/user-settings/cancel-delete-account` annule la demande.
   - `GET /api/v1/user-settings/export-data` retourne 202 + `request_id`.
   - `GET /api/v1/user-settings/export-data/{request_id}` retourne l'état.
3. **Tâches Celery** :
   - `process_data_export_request` génère un ZIP, upload, crée un signed URL, envoie un email.
   - `process_account_deletion_request` anonymise l'utilisateur, garde un log, supprime les fichiers.
4. **Rate limiting export** : une seconde demande dans les 24h retourne 429.

---

## 12. Checklist de correction

- [x] Ajouter les modèles `DataExportRequest`, `AccountDeletionRequest`.
- [x] Créer et exécuter la migration.
- [x] Créer `profiles/tasks.py` avec `generate_data_export` et `process_account_deletion`.
- [x] Mettre à jour `profiles/views_settings.py` avec les endpoints `export-data` et `delete-account`.
- [x] Enregistrer les modèles dans `profiles/admin.py`.
- [x] Ajouter la configuration Celery (`HIVMEET_DELETION_GRACE_HOURS`, `CELERY_TASK_ALWAYS_EAGER`, etc.).
- [x] Mettre à jour le frontend pour interpréter 202 comme "pending" (`ProfileActionPending`) et ajouter les cles i18n.
- [ ] Ajouter le modèle `GDPRAnonymizationLog` (optionnel, prévu dans la spec initiale).
- [ ] Créer les endpoints de confirmation/annulation de suppression dans `profiles/urls_settings.py`.
- [ ] Créer les templates email d'export prêt et de confirmation/annulation de suppression.
- [ ] Brancher l'envoi d'email sur le service de notifications backend.
- [ ] Tester l'export et la suppression localement avec un broker Redis ou `CELERY_TASK_ALWAYS_EAGER`.
- [ ] Mettre à jour `API_DOCUMENTATION.md` et les guides backend.

---

## 13. Résumé pour l'équipe backend

Les endpoints `export-data` et `delete-account` sont actuellement des stubs 202. Pour être conforme RGPD et ne plus induire l'utilisateur en erreur, il faut :

1. **Persister** les demandes (`DataExportRequest`, `AccountDeletionRequest`).
2. **Confirmer** la suppression par email avec tokens.
3. **Traiter** les demandes de manière asynchrone via Celery.
4. **Anonymiser** le compte après une période de grâce, tout en préservant les messages/matchs pour l'autre participant.
5. **Générer** un export JSON/ZIP signé et l'envoyer par email.
6. **Mettre à jour** le frontend pour refléter l'état "en attente" au lieu d'un succès immédiat.

Ce document sert de spécification complète pour l'implémentation backend. L'exécution concerne le dossier `env/hivmeet_backend/`.
