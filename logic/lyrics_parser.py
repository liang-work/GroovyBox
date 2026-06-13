import re
import json
from data.models import LyricsLine, LyricsData


def parse_lrc(content: str) -> LyricsData:
    lines = []
    regex = re.compile(r'\[(\d+):(\d+)\.?(\d+)?\](.*)')
    for line in content.split('\n'):
        m = regex.match(line.strip())
        if m:
            minutes = int(m.group(1))
            seconds = int(m.group(2))
            centiseconds = int(m.group(3) or '0')
            text = m.group(4).strip()
            time_ms = minutes * 60 * 1000 + seconds * 1000 + centiseconds * 10
            if text:
                lines.append(LyricsLine(time_ms=time_ms, text=text))
    lines.sort(key=lambda x: x.time_ms or 0)
    return LyricsData(type="timed", lines=lines)


def parse_srt(content: str) -> LyricsData:
    lines = []
    blocks = re.split(r'\n\s*\n', content)
    time_regex = re.compile(r'(\d+):(\d+):(\d+)[,.](\d+)\s*-->\s*\d+:\d+:\d+[,.]?\d*')
    for block in blocks:
        block_lines = block.strip().split('\n')
        for i, bl in enumerate(block_lines):
            m = time_regex.match(bl)
            if m:
                hours = int(m.group(1))
                minutes = int(m.group(2))
                seconds = int(m.group(3))
                millis = int(m.group(4).ljust(3, '0'))
                time_ms = hours * 3600 * 1000 + minutes * 60 * 1000 + seconds * 1000 + millis
                text = ' '.join(block_lines[i + 1:]).strip()
                if text:
                    lines.append(LyricsLine(time_ms=time_ms, text=text))
                break
    lines.sort(key=lambda x: x.time_ms or 0)
    return LyricsData(type="timed", lines=lines)


def parse_plaintext(content: str) -> LyricsData:
    lines = [
        LyricsLine(text=l.strip())
        for l in content.split('\n')
        if l.strip()
    ]
    return LyricsData(type="plain", lines=lines)


def parse(content: str, filename: str) -> LyricsData:
    lower = filename.lower()
    if lower.endswith('.lrc'):
        return parse_lrc(content)
    elif lower.endswith('.srt'):
        return parse_srt(content)
    else:
        if re.search(r'\[\d+:\d+', content):
            return parse_lrc(content)
        if re.search(r'\d+:\d+:\d+[,.]', content):
            return parse_srt(content)
        return parse_plaintext(content)


def lyrics_to_json(data: LyricsData) -> str:
    return json.dumps({
        "type": data.type,
        "lines": [{"time": l.time_ms, "text": l.text} for l in data.lines],
    }, ensure_ascii=False)


def lyrics_from_json(s: str) -> LyricsData:
    d = json.loads(s)
    return LyricsData(
        type=d.get("type", "plain"),
        lines=[LyricsLine(time_ms=item.get("time"), text=item["text"]) for item in d.get("lines", [])],
    )
