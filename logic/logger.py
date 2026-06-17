import logging
import io

_log_stream = io.StringIO()

LEVEL_MAP = {
    "verbose": logging.DEBUG,
    "normal": logging.INFO,
    "errors_warnings": logging.WARNING,
    "errors_only": logging.ERROR,
}


def _setup_logger():
    logger = logging.getLogger("GroovyBox")
    logger.setLevel(logging.DEBUG)

    formatter = logging.Formatter(
        "[%(asctime)s] %(levelname)s - %(message)s", datefmt="%H:%M:%S"
    )

    ch = logging.StreamHandler()
    ch.setFormatter(formatter)
    logger.addHandler(ch)

    sh = logging.StreamHandler(_log_stream)
    sh.setFormatter(formatter)
    logger.addHandler(sh)

    return logger


logger = _setup_logger()


def set_log_level(level_name: str):
    lvl = LEVEL_MAP.get(level_name, logging.INFO)
    logger.setLevel(lvl)
    for h in logger.handlers:
        h.setLevel(lvl)
    logger.info("Log level set to %s (%d)", level_name, lvl)


def export_logs(path: str):
    with open(path, "w", encoding="utf-8") as f:
        f.write(_log_stream.getvalue())