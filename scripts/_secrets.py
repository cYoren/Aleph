"""Where the scripts get `OPENROUTER_API_KEY` from.

The environment comes first. A `.env` file at the repo root is the fallback,
because the batch jobs in `queue.md` are launched by agent harnesses that spawn
their own shells and do not inherit an `export` from the terminal you typed it
in — which looks exactly like "the key is not set" every single run.

`.env` is gitignored. Nothing here writes it, prints it, or logs it: the value
is read and handed to the caller, and the caller puts it in an Authorization
header.
"""

from __future__ import annotations

import os
import pathlib

REPO = pathlib.Path(__file__).resolve().parent.parent
ENV_FILE = REPO / ".env"

KEY_NAME = "OPENROUTER_API_KEY"

MISSING_MESSAGE = f"""{KEY_NAME} is not set.

Either export it in the shell that launches this script:

    export {KEY_NAME}=sk-or-v1-...

or, if a harness launches the script for you and does not pass the environment
through, put it in a `.env` file at the repo root (already gitignored):

    echo '{KEY_NAME}=sk-or-v1-...' >> .env

The key is never written to any tracked file. Rotate it if it has ever been
pasted into a chat, an issue, or a log."""


def _read_env_file() -> str:
    """The key from `.env`, or an empty string.

    Deliberately a minimal parser rather than a dependency: `KEY=value`, with
    `#` comments, blank lines, and optional surrounding quotes.
    """
    if not ENV_FILE.exists():
        return ""

    try:
        for raw in ENV_FILE.read_text(encoding="utf-8").splitlines():
            line = raw.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            name, _, value = line.partition("=")
            if name.strip() != KEY_NAME:
                continue
            return value.strip().strip("'\"")
    except OSError:
        return ""

    return ""


def openrouter_api_key() -> str:
    """The API key, or an empty string when it is nowhere to be found."""
    return (os.environ.get(KEY_NAME, "") or _read_env_file()).strip()
