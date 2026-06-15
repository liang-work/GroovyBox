import logging
import io

_log_stream = io.StringIO()

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

def export_logs(path: str):
    with open(path, "w", encoding="utf-8") as f:
        f.write(_log_stream.getvalue())