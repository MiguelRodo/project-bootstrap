#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

python3 - "$repo_root" <<'PY'
from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import unquote, urlsplit
import sys
import xml.etree.ElementTree as ET

root = Path(sys.argv[1]).resolve()
site = root / "site"
index = site / "index.html"


class SiteParser(HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.ids = []
        self.local_refs = []
        self.hash_refs = []
        self.copy_targets = []
        self.lang = None
        self.title_depth = 0
        self.title = []
        self.h1_count = 0
        self.description = None

    def handle_starttag(self, tag, attrs):
        values = dict(attrs)
        if tag == "html":
            self.lang = values.get("lang")
        if tag == "title":
            self.title_depth += 1
        if tag == "h1":
            self.h1_count += 1
        if "id" in values:
            self.ids.append(values["id"])
        if tag == "meta" and values.get("name") == "description":
            self.description = values.get("content")
        if "data-copy-target" in values:
            self.copy_targets.append(values["data-copy-target"])
        for attribute in ("href", "src"):
            value = values.get(attribute)
            if not value:
                continue
            parsed = urlsplit(value)
            if parsed.scheme or parsed.netloc or value.startswith("mailto:"):
                continue
            if parsed.path:
                self.local_refs.append(unquote(parsed.path))
            if parsed.fragment:
                self.hash_refs.append(unquote(parsed.fragment))

    def handle_endtag(self, tag):
        if tag == "title" and self.title_depth:
            self.title_depth -= 1

    def handle_data(self, data):
        if self.title_depth:
            self.title.append(data)


parser = SiteParser()
parser.feed(index.read_text(encoding="utf-8"))
parser.close()

errors = []
if parser.lang != "en-GB":
    errors.append("index.html must declare lang=en-GB")
if not "".join(parser.title).strip():
    errors.append("index.html needs a non-empty title")
if not parser.description:
    errors.append("index.html needs a meta description")
if parser.h1_count != 1:
    errors.append(f"index.html must contain one h1, found {parser.h1_count}")

ids = set(parser.ids)
if len(ids) != len(parser.ids):
    errors.append("index.html contains duplicate ids")
for fragment in parser.hash_refs:
    if fragment not in ids:
        errors.append(f"unresolved page anchor: #{fragment}")
for target in parser.copy_targets:
    if target not in ids:
        errors.append(f"copy button points to missing id: {target}")
for reference in parser.local_refs:
    target = (site / reference).resolve()
    try:
        target.relative_to(site.resolve())
    except ValueError:
        errors.append(f"local reference leaves site directory: {reference}")
        continue
    if not target.is_file():
        errors.append(f"missing local asset: {reference}")

ET.parse(site / "mark.svg")

public_text = "\n".join(
    path.read_text(encoding="utf-8", errors="replace")
    for path in sorted(site.rglob("*"))
    if path.is_file()
)
for forbidden in ("/home/mrodo", "ghp_", "github_pat_", "scroll-behaviour", "optimiseLegibility"):
    if forbidden in public_text:
        errors.append(f"public site contains forbidden text: {forbidden}")

if errors:
    for error in errors:
        print(f"website check: {error}", file=sys.stderr)
    raise SystemExit(1)

print("website checks passed")
PY

if command -v node >/dev/null 2>&1; then
  node --check "$repo_root/site/script.js"
fi
