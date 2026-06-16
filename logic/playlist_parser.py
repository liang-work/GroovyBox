import os
import re
from typing import List


def parse_m3u(path: str) -> List[str]:
    encoding = "utf-8-sig"
    for enc in ["utf-8-sig", "utf-8", "gbk", "latin-1"]:
        try:
            with open(path, "r", encoding=enc) as f:
                lines = f.readlines()
            break
        except (UnicodeDecodeError, UnicodeError):
            continue
    else:
        lines = []
    result = []
    base_dir = os.path.dirname(path)
    for line in lines:
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        if not os.path.isabs(line):
            candidate = os.path.normpath(os.path.join(base_dir, line))
        else:
            candidate = line
        if os.path.isfile(candidate):
            result.append(candidate)
    return result


def parse_pls(path: str) -> List[str]:
    encoding = "utf-8-sig"
    for enc in ["utf-8-sig", "utf-8", "gbk", "latin-1"]:
        try:
            with open(path, "r", encoding=enc) as f:
                content = f.read()
            break
        except (UnicodeDecodeError, UnicodeError):
            continue
    else:
        return []

    result = []
    base_dir = os.path.dirname(path)
    for match in re.finditer(r"^File\d+=(.+)$", content, re.MULTILINE):
        file_path = match.group(1).strip()
        if not os.path.isabs(file_path):
            candidate = os.path.normpath(os.path.join(base_dir, file_path))
        else:
            candidate = file_path
        if os.path.isfile(candidate):
            result.append(candidate)
    return result


def parse_playlist(path: str) -> List[str]:
    ext = os.path.splitext(path)[1].lower()
    if ext == ".pls":
        return parse_pls(path)
    else:
        return parse_m3u(path)
