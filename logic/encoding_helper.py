import os

COMMON_ENCODINGS = ["utf-8", "gbk", "shift-jis", "euc-kr", "latin-1", "big5", "euc-jp", "utf-16"]

def _detect_with_chardet(path):
    try:
        import chardet
        with open(path, "rb") as f:
            raw = f.read(min(8192, os.path.getsize(path)))
        result = chardet.detect(raw)
        if result and result["encoding"] and result["confidence"] > 0.5:
            return result["encoding"]
    except ImportError:
        pass
    except Exception:
        pass
    return None


def _detect_by_bom(path):
    with open(path, "rb") as f:
        raw = f.read(4)
    if raw[:3] == b"\xef\xbb\xbf":
        return "utf-8-sig"
    if raw[:2] == b"\xff\xfe":
        return "utf-16-le"
    if raw[:2] == b"\xfe\xff":
        return "utf-16-be"
    return None


def detect_encoding(path):
    bom = _detect_by_bom(path)
    if bom:
        return bom
    chardet_enc = _detect_with_chardet(path)
    if chardet_enc:
        return chardet_enc
    for enc in COMMON_ENCODINGS:
        try:
            with open(path, "r", encoding=enc) as f:
                f.read()
            return enc
        except (UnicodeDecodeError, UnicodeError):
            continue
    return "utf-8"


def read_with_encoding(path, encoding_hint=None):
    if encoding_hint:
        try:
            with open(path, "r", encoding=encoding_hint) as f:
                return f.read()
        except (UnicodeDecodeError, UnicodeError):
            pass
    enc = detect_encoding(path)
    with open(path, "r", encoding=enc, errors="replace") as f:
        return f.read()
