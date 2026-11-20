"""Parse SQL without opening a database or evaluating repository code."""
import pathlib
import sys
import pglast
from pglast import parse_sql

root = pathlib.Path('/workspace')
files = sorted((root / 'supabase/migrations').glob('*.sql'))
files += sorted((root / 'supabase/tests').glob('*.sql'))
files += sorted((root / 'supabase/bootstrap').glob('*.sql'))
files += sorted((root / 'supabase/monitoring').glob('*.sql'))
files += sorted((root / 'scripts/fixtures').glob('*.sql'))
files += sorted((root / 'scripts/security').glob('*.sql'))
errors = []
for file in files:
    try:
        parse_sql(file.read_text(encoding='utf-8-sig'))
    except Exception as error:
        errors.append(f'{file.relative_to(root)}: {error}')
if errors:
    print('\n'.join(errors), file=sys.stderr)
    sys.exit(1)
print(f'SQL_PARSE_PASS files={len(files)} pglast={pglast.__version__}')
