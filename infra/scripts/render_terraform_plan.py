#!/usr/bin/env python3
"""Render a Terraform plan report for a pull request and job summary."""

from __future__ import annotations

import argparse
import re
from pathlib import Path

MAX_COMMENT_BYTES = 55_000
CHECKS = ("fmt", "init", "validate", "plan")


def _tail_by_bytes(text: str, max_bytes: int) -> str:
    tail: list[str] = []
    used = 0
    for character in reversed(text):
        size = len(character.encode("utf-8"))
        if used + size > max_bytes:
            break
        tail.append(character)
        used += size
    return "".join(reversed(tail))


def render_plan(
    environment: str,
    statuses: dict[str, str],
    changes: str,
    plan_text: str,
    run_url: str,
    max_bytes: int = MAX_COMMENT_BYTES,
) -> str:
    status_rows = "\n".join(
        f"| {check} | {statuses.get(check, 'skipped')} |" for check in CHECKS
    )
    prefix = (
        f"<!-- terraform-plan: {environment} -->\n\n"
        f"## Terraform plan — `{environment}`\n\n"
        "| Check | Status |\n| --- | --- |\n"
        f"{status_rows}\n\n"
        f"**Changes:** `{changes}`\n\n"
        "<details>\n<summary>Full Terraform diff</summary>\n\n"
    )
    longest_backtick_run = max(
        (len(run) for run in re.findall(r"`+", plan_text)), default=0
    )
    fence = "`" * max(3, longest_backtick_run + 1)
    opening = f"{fence}\n"
    closing = f"\n{fence}\n\n</details>\n\n[View workflow run]({run_url})"
    body = f"{prefix}{opening}{plan_text}{closing}"
    if len(body.encode("utf-8")) <= max_bytes:
        return body

    truncation_note = "[Plan truncated; showing the tail of the output.]\n"
    fixed_bytes = len(f"{prefix}{opening}{truncation_note}{closing}".encode("utf-8"))
    if fixed_bytes > max_bytes:
        raise ValueError("comment limit is too small for the Terraform report header")
    tail = _tail_by_bytes(plan_text, max_bytes - fixed_bytes)
    return f"{prefix}{opening}{truncation_note}{tail}{closing}"


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--environment", required=True)
    parser.add_argument("--changes", required=True)
    parser.add_argument("--plan-file", required=True, type=Path)
    parser.add_argument("--run-url", required=True)
    parser.add_argument("--output-file", required=True, type=Path)
    for check in CHECKS:
        parser.add_argument(f"--{check}-status", required=True)
    args = parser.parse_args()

    statuses = {check: getattr(args, f"{check}_status") for check in CHECKS}
    plan_text = args.plan_file.read_text(encoding="utf-8", errors="replace")
    body = render_plan(
        args.environment, statuses, args.changes, plan_text, args.run_url
    )
    args.output_file.write_text(body, encoding="utf-8")


if __name__ == "__main__":
    main()
