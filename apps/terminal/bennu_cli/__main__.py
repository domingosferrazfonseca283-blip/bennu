from __future__ import annotations

import argparse
import json
import os
import sys
import urllib.error
import urllib.request


def _api_base() -> str:
    return os.environ.get("BENNU_API_URL", "http://127.0.0.1:8000").rstrip("/")


def _get(path: str) -> tuple[int, str]:
    request = urllib.request.Request(f"{_api_base()}{path}", headers={"Accept": "application/json"})
    try:
        with urllib.request.urlopen(request, timeout=10) as response:
            return response.status, response.read().decode("utf-8", errors="replace")
    except urllib.error.HTTPError as exc:
        return exc.code, exc.read().decode("utf-8", errors="replace")
    except urllib.error.URLError as exc:
        return 503, json.dumps({"error": str(exc.reason)})


def main() -> int:
    parser = argparse.ArgumentParser(prog="bennu", description="Bennu Core API CLI")
    sub = parser.add_subparsers(dest="command", required=True)
    sub.add_parser("status")
    sub.add_parser("agent-list")
    sub.add_parser("security-status")
    args = parser.parse_args()

    paths = {
        "status": "/health",
        "agent-list": "/agents",
        "security-status": "/security/status",
    }
    status, body = _get(paths[args.command])
    print(body)
    return 0 if 200 <= status < 300 else 1


if __name__ == "__main__":
    sys.exit(main())
