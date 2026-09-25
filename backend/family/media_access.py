import mimetypes
from pathlib import PurePosixPath
from urllib.parse import urlencode

from django.core import signing
from django.core.files.storage import default_storage
from django.http import FileResponse, Http404
from django.urls import reverse


_SALT = 'family-private-media-v1'
_MAX_AGE_SECONDS = 300


def signed_media_url(field_file, request=None):
    if not field_file:
        return None
    token = signing.dumps(field_file.name, salt=_SALT)
    path = f"{reverse('signed_media')}?{urlencode({'token': token})}"
    return request.build_absolute_uri(path) if request else path


def serve_signed_media(request):
    try:
        name = signing.loads(request.GET.get('token', ''), salt=_SALT,
                             max_age=_MAX_AGE_SECONDS)
        path = PurePosixPath(name)
        if (not isinstance(name, str) or path.is_absolute() or
                '..' in path.parts or '\\' in name or
                not default_storage.exists(name)):
            raise Http404
        content_type = mimetypes.guess_type(name)[0] or 'application/octet-stream'
        response = FileResponse(default_storage.open(name, 'rb'),
                                content_type=content_type)
        # Images can render in the app; other uploads download instead of
        # executing in the browser's origin.
        if content_type not in ('image/jpeg', 'image/png', 'image/gif', 'image/webp'):
            response['Content-Disposition'] = 'attachment'
        response['Cache-Control'] = 'private, max-age=300'
        response['X-Content-Type-Options'] = 'nosniff'
        return response
    except (signing.BadSignature, ValueError, TypeError):
        raise Http404
