import unicodedata


def normalized(value):
    value = unicodedata.normalize('NFKD', str(value or '')).casefold()
    return ' '.join(''.join(c for c in value if not unicodedata.combining(c)).split())
