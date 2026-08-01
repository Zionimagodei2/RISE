#!/usr/bin/env python3
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
PLACEHOLDER_PATTERNS = [
    r'placeholder', r'TODO', r'stub', r'not implemented', r'will .* later',
    r'initialize\(\) async \{\}', r'return true;\s*$',
    r'validate\(Object input\) => true',
    r"Center\(child: Text\('[A-Za-z]+Screen'\)",
    r"Text\('[A-Za-z]+Screen'\)",
    r"Text\('[A-Za-z]+Widget'\)",
    r"Text\('[A-Za-z]+(Settings|Step|Card|Header|Gate|Panel|Picker)'\)",
    r"=> const (ListTile|Text)\(",
    r"class [A-Za-z]+Service \{ const [A-Za-z]+Service\(\); \}",
]
IGNORE_GLOBS = ['.git', 'RISE_', 'build', 'dist']

def ignored(path: Path) -> bool:
    text = str(path.relative_to(ROOT))
    return any(part.startswith('.git') for part in path.parts) or text.startswith('RISE_') or '/build/' in text or '/dist/' in text

def blueprint_paths():
    refs = []
    for md in ROOT.glob('RISE_PART_*.md'):
        for line in md.read_text(encoding='utf-8').splitlines():
            match = re.search(r'((?:lib|android|ios)/[^\s)]+)', line)
            if not match:
                continue
            path = match.group(1).rstrip('.,:←')
            if '...' in path:
                continue
            refs.append((md.name, path))
    return sorted(set(refs))

def main() -> int:
    missing = [(md, path) for md, path in blueprint_paths() if not (ROOT / path).exists()]
    scanned_files = [p for p in ROOT.rglob('*') if p.is_file() and not ignored(p)]
    placeholder_hits = []
    for file_path in scanned_files:
        if file_path.suffix not in {'.dart', '.kt', '.swift', '.xml', '.yaml', '.md', '.gradle'}:
            continue
        for number, line in enumerate(file_path.read_text(encoding='utf-8', errors='ignore').splitlines(), 1):
            for pattern in PLACEHOLDER_PATTERNS:
                if re.search(pattern, line, flags=re.IGNORECASE):
                    placeholder_hits.append((str(file_path.relative_to(ROOT)), number, line.strip()))
    duplicate_legacy_android = (ROOT / 'android/app/src/main/kotlin/com/rise/app').exists()
    print(f'blueprint_path_refs={len(blueprint_paths())}')
    print(f'missing_blueprint_paths={len(missing)}')
    print(f'placeholder_hits={len(placeholder_hits)}')
    print(f'duplicate_legacy_android_package={duplicate_legacy_android}')
    for md, path in missing:
        print(f'MISSING {path} from {md}')
    for path, number, line in placeholder_hits:
        print(f'PLACEHOLDER {path}:{number}: {line}')
    return 1 if missing or placeholder_hits or duplicate_legacy_android else 0

if __name__ == '__main__':
    raise SystemExit(main())
