import os
import sys

# Ensure PostgreSQL client DLLs can be loaded on Windows
if sys.platform == 'win32':
    for pg_bin in [
        r'C:\Program Files\PostgreSQL\17\bin',
        r'C:\Program Files\PostgreSQL\16\bin',
        r'C:\OSGeo4W\bin',
    ]:
        if os.path.isdir(pg_bin):
            try:
                os.add_dll_directory(pg_bin)
            except Exception:
                pass
