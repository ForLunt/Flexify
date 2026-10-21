#!/usr/bin/env python3
import glob
import json
import os
import re
import sys

ARB_DIR = "lib/l10n"
NOT_TRANSLATED = {"Flexitrack"}

ARGOS = {
    "ar": "ar", "bn": "bn", "de": "de", "es": "es", "fa": "fa", "fr": "fr",
    "hi": "hi", "id": "id", "it": "it", "ja": "ja", "ko": "ko", "ms": "ms",
    "nl": "nl", "pl": "pl", "pt": "pt", "pt_BR": "pt", "pt_PT": "pt",
    "ru": "ru", "th": "th", "tr": "tr", "uk": "uk", "ur": "ur", "vi": "vi",
    "zh": "zh", "zh_CN": "zh", "zh_TW": "zt",
}
SAME_AS = {"pt": "pt_PT", "zh": "zh_CN"}
CURLY_APOSTROPHE = {"fr"}

PLACEHOLDER = re.compile(r"\{([A-Za-z_][A-Za-z0-9_]*)\s*(?:,|\})")
SIMPLE = re.compile(r"\{([A-Za-z_][A-Za-z0-9_]*)\}")
ICU = re.compile(r"\{[A-Za-z_][A-Za-z0-9_]*\s*,\s*(plural|select|selectordinal)\b")


def load(path):
    with open(path, encoding="utf-8") as f:
        return json.load(f)


def message_keys(data):
    return [k for k in data if not k.startswith("@") and k != "@@locale"]


def append_entries(path, entries):
    with open(path, encoding="utf-8") as f:
        text = f.read()
    match = re.search(r'^( +)"', text, re.M)
    pad = " " * (len(match.group(1)) if match else 2)
    stripped = text.rstrip()
    if not stripped.endswith("}"):
        raise ValueError(f"{path}: fichier .arb invalide")
    body = stripped[:-1].rstrip()
    sep = "" if body.endswith("{") else ","
    lines = [
        f"{pad}{json.dumps(k, ensure_ascii=False)}: "
        f"{json.dumps(v, ensure_ascii=False)}"
        for k, v in entries.items()
    ]
    result = body + sep + "\n" + ",\n".join(lines) + "\n}\n"
    json.loads(result)
    with open(path, "w", encoding="utf-8") as f:
        f.write(result)


class Argos:
    def __init__(self):
        import argostranslate.package as package
        import argostranslate.translate as translate

        self.package = package
        self.translate_module = translate
        package.update_package_index()
        self.available = package.get_available_packages()
        self.ready = {}

    def has_model(self, code):
        if code in self.ready:
            return self.ready[code]
        installed = {
            (p.from_code, p.to_code) for p in self.package.get_installed_packages()
        }
        ok = ("en", code) in installed
        if not ok:
            match = next(
                (
                    p
                    for p in self.available
                    if p.from_code == "en" and p.to_code == code
                ),
                None,
            )
            if match:
                self.package.install_from_path(match.download())
                ok = True
        self.ready[code] = ok
        return ok

    def translate(self, text, code):
        # Découpe autour des {placeholders} et ne traduit que le texte
        parts = SIMPLE.split(text)  # indices impairs = noms de placeholders
        out = []
        for i, part in enumerate(parts):
            if i % 2 == 1:
                out.append("{" + part + "}")
            elif part:
                out.append(self.translate_module.translate(part, "en", code).strip())
        out = "".join(out)
        if not out:
            raise ValueError("traduction vide")
        if set(PLACEHOLDER.findall(out)) != set(PLACEHOLDER.findall(text)):
            raise ValueError("paramètres {…} altérés par la traduction")
        return out

def main():
    check_only = "--check" in sys.argv
    template = load(f"{ARB_DIR}/app_en.arb")
    keys = message_keys(template)

    todo = {}
    for path in sorted(glob.glob(f"{ARB_DIR}/app_*.arb")):
        loc = os.path.basename(path)[4:-4]
        if loc == "en":
            continue
        existing = load(path)
        extra = [k for k in message_keys(existing) if k not in template]
        if extra:
            print(f"WARN {loc}: clés absentes de app_en.arb : {extra}")
        missing = [k for k in keys if k not in existing]
        if missing:
            todo[loc] = (path, missing)

    if check_only:
        for loc, (_, missing) in todo.items():
            print(f"{loc}: {len(missing)} clé(s) manquante(s)")
        return 10 if todo else 0

    if not todo:
        print("Rien à traduire.")
        return 0

    argos = None
    cache = {}
    results = {}
    failures = []

    for loc, (path, missing) in todo.items():
        src = SAME_AS.get(loc, loc)
        code = ARGOS.get(src)
        entries = {}
        for key in missing:
            text = template[key]
            value = text if text in NOT_TRANSLATED else None
            if value is None:
                if ICU.search(text):
                    failures.append(f"{loc}.{key}: message pluriel/select, à traduire à la main")
                    continue
                if code is None:
                    failures.append(f"{loc}.{key}: langue inconnue du script")
                    continue
                if argos is None:
                    argos = Argos()
                if not argos.has_model(code):
                    failures.append(f"{loc}.{key}: aucun modèle Argos en->{code}")
                    continue
                try:
                    if (code, text) not in cache:
                        cache[(code, text)] = argos.translate(text, code)
                    value = cache[(code, text)]
                except Exception as e:
                    failures.append(f"{loc}.{key}: {e}")
                    continue
            if loc in CURLY_APOSTROPHE:
                value = value.replace("'", "’")
            if value == text:
                print(f"INFO {loc}.{key}: identique à l'anglais")
            entries[key] = value
        results[path] = entries

    if failures:
        print("\nÉCHEC, rien n'a été écrit. Ces clés sont à ajouter à la main dans les .arb :")
        for f in failures:
            print(f"  - {f}")
        return 1

    for path, entries in results.items():
        if entries:
            append_entries(path, entries)
            print(f"OK {path}: {len(entries)} clé(s) ajoutée(s)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
