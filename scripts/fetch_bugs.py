"""
Download real Firefox defect reports from Mozilla's public Bugzilla REST API.

Source: https://bugzilla.mozilla.org (public, no login needed)
Output: data/raw/firefox_bugs_2023_2025.csv

Run from the project folder:
    python scripts/fetch_bugs.py
"""

import time
from pathlib import Path

import pandas as pd
import requests

API_URL = "https://bugzilla.mozilla.org/rest/bug"
PAGE_SIZE = 1000
OUTPUT = Path(__file__).resolve().parent.parent / "data" / "raw" / "firefox_bugs_2023_2025.csv"

FIELDS = [
    "id", "summary", "product", "component", "type", "severity", "priority",
    "status", "resolution", "creation_time", "cf_last_resolved", "last_change_time",
    "keywords", "regressed_by", "op_sys", "platform", "version",
    "is_confirmed", "comment_count", "duplicates", "votes",
]

params = {
    "product": "Firefox",
    "type": "defect",
    "chfield": "[Bug creation]",
    "chfieldfrom": "2023-01-01",
    "chfieldto": "2025-12-31",
    "include_fields": ",".join(FIELDS),
    "order": "bug_id",
    "limit": PAGE_SIZE,
}

all_bugs = []
offset = 0
while True:
    params["offset"] = offset
    response = requests.get(API_URL, params=params, timeout=120)
    response.raise_for_status()
    bugs = response.json()["bugs"]
    if not bugs:
        break
    all_bugs.extend(bugs)
    print(f"Downloaded {len(all_bugs)} bugs so far...")
    offset += PAGE_SIZE
    time.sleep(1)  # be polite to Mozilla's servers

df = pd.DataFrame(all_bugs)

# Lists don't fit nicely in a CSV, so turn them into text / counts
df["keywords"] = df["keywords"].apply(lambda k: ";".join(k))
df["regressed_by_count"] = df["regressed_by"].apply(len)
df["duplicates_count"] = df["duplicates"].apply(len)
df = df.drop(columns=["regressed_by", "duplicates"])

OUTPUT.parent.mkdir(parents=True, exist_ok=True)
df.to_csv(OUTPUT, index=False)
print(f"Saved {len(df)} bugs to {OUTPUT}")
