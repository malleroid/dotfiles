#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.12"
# dependencies = []
# ///
"""Scan the agent skills pulled in by .chezmoiexternal.toml with SkillSpector.

Each skill is rebuilt the way chezmoi lays it out (download the archive, keep the
`include` matches, drop `stripComponents` leading segments) without running chezmoi,
then scanned with static analysis only (--no-llm), so no file contents leave the runner.

Usage:
  .github/scripts/scan-external-skills.py

Findings reviewed as false positives are suppressed by the per-skill baselines in
.github/skillspector-baselines/, and incomplete-analysis exceptions that a baseline cannot
suppress are allowed in .github/skillspector-baselines/allowed-exceptions.toml.

Exit status:
  0  every skill is SAFE
  1  at least one skill is CAUTION or DO_NOT_INSTALL
  2  a skill could not be rebuilt or scanned
"""

import html
import io
import json
import os
import re
import subprocess
import sys
import tarfile
import tempfile
import tomllib
import urllib.request
from collections.abc import Iterable, Mapping
from dataclasses import dataclass
from enum import IntEnum
from pathlib import Path, PurePosixPath
from typing import Any

REPO_ROOT = Path(__file__).resolve().parents[2]
EXTERNALS = REPO_ROOT / ".chezmoiexternal.toml"
BASELINES = REPO_ROOT / ".github" / "skillspector-baselines"
ALLOWED_EXCEPTIONS = BASELINES / "allowed-exceptions.toml"
SKILLSPECTOR = os.environ.get("SKILLSPECTOR", "skillspector")
DOWNLOAD_TIMEOUT_SECONDS = 120
# Missing references alone still count as a complete analysis, so they need no allowance.
CAVEAT_REASONS = frozenset({"reference_missing"})

type Report = dict[str, Any]
type LedgerException = Mapping[str, Any]


class ExitCode(IntEnum):
    OK = 0
    BLOCKED = 1
    ERROR = 2


class SkillError(Exception):
    """A skill could not be rebuilt or scanned."""


@dataclass(frozen=True, slots=True)
class Allowance:
    """A reviewed analysis-completeness exception that a baseline cannot suppress."""

    skill: str
    reason_code: str
    path: str
    reason: str

    def covers(self, skill: str, exception: LedgerException) -> bool:
        return (self.skill, self.reason_code, self.path) == (
            skill,
            exception.get("reason_code"),
            exception.get("path"),
        )


def load_allowances(path: Path) -> list[Allowance]:
    if not path.is_file():
        return []
    entries = tomllib.loads(path.read_text(encoding="utf-8")).get("exception", [])
    allowances = [Allowance(**entry) for entry in entries]
    if missing := [a for a in allowances if not a.reason.strip()]:
        raise ValueError(f"allowance without a reason: {missing[0]}")
    return allowances


@dataclass(frozen=True, slots=True)
class Scanned:
    target: str
    report: Report
    allowances: tuple[Allowance, ...] = ()

    @property
    def skill(self) -> str:
        return PurePosixPath(self.target).name

    @property
    def exceptions(self) -> list[LedgerException]:
        return (self.report.get("analysis_completeness") or {}).get("ledger_exceptions") or []

    def allowance_for(self, exception: LedgerException) -> Allowance | None:
        return next((a for a in self.allowances if a.covers(self.skill, exception)), None)

    @property
    def raw_recommendation(self) -> str:
        return self.report["risk_assessment"]["recommendation"]

    @property
    def recommendation(self) -> str:
        """SkillSpector's verdict, lifted to SAFE when only allowed exceptions made it CAUTION."""
        risk = self.report["risk_assessment"]
        completeness = self.report.get("analysis_completeness") or {}
        if (
            risk["recommendation"] != "CAUTION"
            or risk.get("severity") != "LOW"
            or not self.report.get("execution_successful", False)
            or completeness.get("entirely_uninspected_files", 0)
        ):
            return risk["recommendation"]
        relevant = [e for e in self.exceptions if e.get("reason_code") not in CAVEAT_REASONS]
        if relevant and all(self.allowance_for(e) for e in relevant):
            return "SAFE"
        return risk["recommendation"]


@dataclass(frozen=True, slots=True)
class Failed:
    target: str
    message: str


def glob_to_regex(pattern: str) -> re.Pattern[str]:
    """Translate a chezmoi include pattern (doublestar semantics) into a regex.

    `**` spans any number of path segments, including none, while `*` and `?` stay
    within one segment.
    """
    tokens = re.split(r"(/\*\*/|\*\*|\*|\?)", pattern)
    translated = {"/**/": "/(?:.*/)?", "**": ".*", "*": "[^/]*", "?": "[^/]"}
    return re.compile("".join(translated.get(t, re.escape(t)) for t in tokens))


class ArchiveCache:
    """Downloads each archive URL once; the docker skills share a single tarball."""

    def __init__(self) -> None:
        self._archives: dict[str, bytes] = {}

    def get(self, url: str) -> bytes:
        if url not in self._archives:
            with urllib.request.urlopen(url, timeout=DOWNLOAD_TIMEOUT_SECONDS) as response:
                self._archives[url] = response.read()
        return self._archives[url]


def extract(archive: bytes, dest: Path, include: Iterable[str], strip: int) -> int:
    """Write the matching regular files of a .tar.gz into dest and return how many.

    The archive is untrusted: links, devices, absolute paths, and `..` segments are
    skipped rather than followed, and only the execute bits of each mode are kept.
    """
    patterns = [glob_to_regex(p) for p in include]
    root = dest.resolve()
    written = 0
    with tarfile.open(fileobj=io.BytesIO(archive), mode="r:gz") as tar:
        for member in tar:
            if not member.isreg():
                continue
            path = PurePosixPath(member.name.removeprefix("./"))
            if patterns and not any(p.fullmatch(path.as_posix()) for p in patterns):
                continue
            parts = path.parts[strip:]
            if path.is_absolute() or not parts or ".." in parts:
                continue
            target = root.joinpath(*parts)
            if not target.is_relative_to(root):
                continue
            source = tar.extractfile(member)
            if source is None:
                continue
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(source.read())
            target.chmod(0o644 | (member.mode & 0o111))
            written += 1
    return written


def scan(skill_dir: Path, report_path: Path, baseline: Path | None) -> Report:
    command = [SKILLSPECTOR, "scan", skill_dir, "--no-llm", "--format", "json", "--output", report_path]
    if baseline is not None:
        command += ["--baseline", baseline]
    result = subprocess.run(
        command,
        capture_output=True,
        text=True,
        check=False,
    )
    # Exit 1 only means the risk score is high; the report is still complete.
    if result.returncode not in (0, 1) or not report_path.is_file():
        raise SkillError(result.stderr.strip() or f"skillspector exited with {result.returncode}")
    return json.loads(report_path.read_text(encoding="utf-8"))


def scan_external(
    target: str,
    spec: Mapping[str, Any],
    cache: ArchiveCache,
    work: Path,
    allowances: Iterable[Allowance],
) -> Scanned:
    url = spec.get("url", "")
    if spec.get("type") != "archive" or not url.endswith(".tar.gz"):
        raise SkillError(f"unsupported external: type={spec.get('type')!r} url={url!r}")
    skill_dir = work / "skills" / target
    count = extract(cache.get(url), skill_dir, spec.get("include", []), spec.get("stripComponents", 0))
    if count == 0:
        raise SkillError("no files matched include")
    report_path = work / "reports" / f"{target.replace('/', '_')}.json"
    report_path.parent.mkdir(parents=True, exist_ok=True)
    skill = PurePosixPath(target).name
    baseline = BASELINES / f"{skill}.yaml"
    report = scan(skill_dir, report_path, baseline if baseline.is_file() else None)
    return Scanned(target, report, tuple(a for a in allowances if a.skill == skill))


TEXT_LIMIT = 200
LOCATION_LIMIT = 5
# Scanned content is untrusted; neutralize characters that Markdown or a table would interpret.
MARKDOWN_ESCAPES = str.maketrans({c: f"&#{ord(c)};" for c in "|`*_[]~\\"})


def text(value: object, limit: int = TEXT_LIMIT) -> str:
    flat = " ".join(str(value).split())
    if len(flat) > limit:
        flat = flat[: limit - 1] + "…"
    return html.escape(flat).translate(MARKDOWN_ESCAPES)


def matched(issue: Mapping[str, Any]) -> str:
    # Quoted and JSON-escaped so baseline `message` patterns can be written against the exact text.
    return text(json.dumps(issue.get("finding") or "", ensure_ascii=False))


def locations(issue: Mapping[str, Any]) -> str:
    occurrences = issue.get("occurrences") or [issue.get("location") or {}]
    shown = [f"{o.get('file', '?')}:{o.get('start_line', '?')}" for o in occurrences[:LOCATION_LIMIT]]
    if (extra := len(occurrences) - LOCATION_LIMIT) > 0:
        shown.append(f"+{extra} more")
    return "<br>".join(text(where) for where in shown)


def verdict(s: Scanned) -> str:
    if s.recommendation == s.raw_recommendation:
        return text(s.recommendation)
    return f"{text(s.recommendation)} (allowed {text(s.raw_recommendation)})"


def exception_line(s: Scanned, e: LedgerException) -> str:
    line = (
        f"- {text(e.get('reason_code', '?'))}: {text(e.get('message', ''))} "
        f"({text(e.get('path', '-'))}:{text(e.get('start_line') or '-')})"
    )
    if allowance := s.allowance_for(e):
        line += f" — allowed: {text(allowance.reason)}"
    return line


def render_skill(s: Scanned) -> list[str]:
    risk = s.report["risk_assessment"]
    issues = s.report.get("issues", [])
    suppressed = s.report.get("suppressed", [])
    completeness = s.report.get("analysis_completeness") or {}
    if not issues and not suppressed and not s.exceptions:
        return []

    is_open = " open" if s.recommendation != "SAFE" else ""
    lines = [
        "",
        f"<details{is_open}><summary><code>{text(s.target)}</code>: {verdict(s)}, "
        f"score {text(risk['score'])}, {len(issues)} issues, {len(suppressed)} suppressed</summary>",
        "",
        f"Analysis: {text(completeness.get('status', '?'))}",
    ]
    lines += [exception_line(s, e) for e in s.exceptions]
    if issues:
        lines += [
            "",
            "| Severity | Rule | Location | Finding | Explanation |",
            "| --- | --- | --- | --- | --- |",
        ]
        lines += [
            f"| {text(i.get('severity', '?'))} | {text(i.get('id', '?'))} | {locations(i)} "
            f"| <code>{matched(i)}</code> | {text(i.get('explanation') or '')} |"
            for i in issues
        ]
    if suppressed:
        lines += [
            "",
            "| Suppressed rule | Location | Reason |",
            "| --- | --- | --- |",
        ]
        lines += [
            f"| {text(i.get('id', '?'))} | {locations(i)} | {text(i.get('suppression_reason', ''))} |"
            for i in suppressed
        ]
    return [*lines, "", "</details>"]


def render(scanned: list[Scanned], failed: list[Failed]) -> str:
    lines = [
        "## External skill scan",
        "",
        "| Skill | Recommendation | Score | Analysis | Issues | Suppressed |",
        "| --- | --- | --- | --- | --- | --- |",
    ]
    for s in scanned:
        risk = s.report["risk_assessment"]
        status = (s.report.get("analysis_completeness") or {}).get("status", "?")
        lines.append(
            f"| <code>{text(s.target)}</code> | {verdict(s)} | {text(risk['score'])} "
            f"| {text(status)} | {len(s.report.get('issues', []))} | {len(s.report.get('suppressed', []))} |"
        )
    lines += [f"| <code>{text(f.target)}</code> | ERROR | - | - | {text(f.message)} | - |" for f in failed]
    for s in scanned:
        lines += render_skill(s)
    return "\n".join(lines) + "\n"


def annotate(level: str, message: str) -> None:
    # Workflow command values must escape %, CR, and LF.
    escaped = message.replace("%", "%25").replace("\r", "%0D").replace("\n", "%0A")
    print(f"::{level} title=SkillSpector::{escaped}")


def main() -> ExitCode:
    externals = tomllib.loads(EXTERNALS.read_text(encoding="utf-8"))
    try:
        allowances = load_allowances(ALLOWED_EXCEPTIONS)
    except (OSError, tomllib.TOMLDecodeError, TypeError, ValueError) as error:
        annotate("error", f"{ALLOWED_EXCEPTIONS.relative_to(REPO_ROOT)}: {error}")
        return ExitCode.ERROR
    cache = ArchiveCache()
    scanned: list[Scanned] = []
    failed: list[Failed] = []

    # SkillSpector refuses output paths with symlinked parents (macOS /var -> /private/var).
    with tempfile.TemporaryDirectory(dir=os.environ.get("RUNNER_TEMP")) as tmp:
        work = Path(tmp).resolve()
        for target, spec in externals.items():
            print(f"Scanning {target}", file=sys.stderr)
            try:
                scanned.append(scan_external(target, spec, cache, work, allowances))
            except (SkillError, OSError, tarfile.TarError, json.JSONDecodeError) as error:
                failed.append(Failed(target, str(error)))

    summary = render(scanned, failed)
    if summary_path := os.environ.get("GITHUB_STEP_SUMMARY"):
        with open(summary_path, "a", encoding="utf-8") as f:
            f.write(summary)
    else:
        sys.stdout.write(summary)

    for s in scanned:
        if s.recommendation != "SAFE":
            annotate("error", f"{s.target} is {s.recommendation}")
    for f in failed:
        annotate("error", f"{f.target}: {f.message}")
    used = {a for s in scanned for e in s.exceptions if (a := s.allowance_for(e))}
    for a in allowances:
        if a not in used:
            annotate("warning", f"Unused allowance for {a.skill}: {a.reason_code} in {a.path}")

    if failed:
        return ExitCode.ERROR
    if any(s.recommendation != "SAFE" for s in scanned):
        return ExitCode.BLOCKED
    return ExitCode.OK


if __name__ == "__main__":
    sys.exit(main())
