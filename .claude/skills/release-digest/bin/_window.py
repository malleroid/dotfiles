"""Shared date-window helpers for release-digest parsers.

All sources are filtered on a single, consistent basis: the JST (UTC+9) calendar date.
- `cutoff_date(days)` is "JST today minus N days" (a date).
- `jst_date(dt)` converts a timezone-aware timestamp to its JST calendar date.

Sources that expose only a bare date (no time/zone) use that date as-is — it is the
publisher's local date and cannot be converted — and are compared at date granularity.
Japan has no DST, so a fixed +9h offset equals Asia/Tokyo year-round.
"""
from datetime import datetime, timezone, timedelta

JST = timezone(timedelta(hours=9))


def cutoff_date(days):
    return datetime.now(JST).date() - timedelta(days=days)


def jst_date(dt):
    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=timezone.utc)
    return dt.astimezone(JST).date()
