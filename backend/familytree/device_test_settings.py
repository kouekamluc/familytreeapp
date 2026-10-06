"""Isolated local settings for physical-device regression tests only."""
from .settings import *  # noqa
from datetime import timedelta

BASE_DIR = Path(__file__).resolve().parent.parent / '.device-test'
BASE_DIR.mkdir(exist_ok=True)
DATABASES = {'default': {'ENGINE': 'django.db.backends.sqlite3', 'NAME': BASE_DIR / 'db.sqlite3'}}
MEDIA_ROOT = BASE_DIR / 'media'
DEBUG = True
ALLOWED_HOSTS = ['localhost', '127.0.0.1', 'testserver']
SIMPLE_JWT = {**SIMPLE_JWT, 'ACCESS_TOKEN_LIFETIME': timedelta(seconds=5)}
EMAIL_BACKEND = 'django.core.mail.backends.filebased.EmailBackend'
EMAIL_FILE_PATH = str(BASE_DIR / 'outbox')
