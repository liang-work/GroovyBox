"""Logging Module for GroovyBox.

This module provides a centralized logging system with configurable
log levels and the ability to export logs to a file. Supports both
console output and in-memory log capture for export.
"""

import logging
import io

# In-memory stream to capture log messages for export
_log_stream = io.StringIO()

# Mapping of user-friendly log level names to Python logging levels
LEVEL_MAP = {
    "verbose": logging.DEBUG,
    "normal": logging.INFO,
    "errors_warnings": logging.WARNING,
    "errors_only": logging.ERROR,
}


def _setup_logger():
    """Initialize and configure the application logger.
    
    Creates a logger named "GroovyBox" with two handlers:
    - StreamHandler: Outputs to console (stderr)
    - StringHandler: Captures to in-memory buffer for export
    
    Both handlers use a timestamped format: [HH:MM:SS] LEVEL - message
    
    Returns:
        The configured logging.Logger instance.
    """
    logger = logging.getLogger("GroovyBox")
    logger.setLevel(logging.DEBUG)

    formatter = logging.Formatter(
        "[%(asctime)s] %(levelname)s - %(message)s", datefmt="%H:%M:%S"
    )

    # Console handler for real-time output
    ch = logging.StreamHandler()
    ch.setFormatter(formatter)
    logger.addHandler(ch)

    # In-memory handler for log export
    sh = logging.StreamHandler(_log_stream)
    sh.setFormatter(formatter)
    logger.addHandler(sh)

    return logger


# Global logger instance used throughout the application
logger = _setup_logger()


def set_log_level(level_name: str):
    """Set the application log level.
    
    Args:
        level_name: One of "verbose", "normal", "errors_warnings", or "errors_only".
    """
    lvl = LEVEL_MAP.get(level_name, logging.INFO)
    logger.setLevel(lvl)
    for h in logger.handlers:
        h.setLevel(lvl)
    logger.info("Log level set to %s (%d)", level_name, lvl)


def export_logs(path: str):
    """Export captured log messages to a text file.
    
    Writes all log messages captured since application start to the
    specified file path.
    
    Args:
        path: Absolute path for the output log file.
    """
    with open(path, "w", encoding="utf-8") as f:
        f.write(_log_stream.getvalue())
