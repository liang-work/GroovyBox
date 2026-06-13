import json
import os

_locale = "en"
_strings: dict = {}


def load_locale(lang: str):
    global _locale, _strings
    _locale = lang
    path = os.path.join(os.path.dirname(__file__), "..", "assets", "locales", f"{lang}.json")
    try:
        with open(path, "r", encoding="utf-8") as f:
            _strings = json.load(f)
    except FileNotFoundError:
        _strings = {}


def tr(key: str, *args) -> str:
    val = _strings.get(key, key)
    if args:
        for a in args:
            val = val.replace("{}", str(a), 1)
    return val


def get_locale() -> str:
    return _locale
