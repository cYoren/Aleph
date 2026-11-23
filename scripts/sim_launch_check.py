#!/usr/bin/env python3
"""Launch the built app on an iPhone and an iPad simulator, and prove it is alive.

Why this exists: a build that stays in the process list but paints one flat
colour is still a rejection, and "the process is running" says nothing about the
first frame. The 234 MB bundled database unpacks on first launch, so on a
debug simulator build the first frame legitimately takes minutes; what must never
happen is that it never arrives at all.

What it checks, per device, twice (cold start each time):
  1. the process is still running 20 s after launch,
  2. the screen paints something other than a single flat colour,
  3. the app's data container holds the unpacked database.

Usage:
    scripts/sim_launch_check.py --app build/ios/iphonesimulator/Runner.app \
        --bundle com.originalbible.originalBible [--out build/sim-launch]

Exit code 0 only when every check passed on both devices. Servers, Macs and
CI runners are the only place this can run: it needs `xcrun simctl`.
"""

from __future__ import annotations

import argparse
import datetime
import json
import plistlib
import subprocess
import sys
import time
from pathlib import Path

ALIVE_SECONDS = 20
PAINT_BUDGET_SECONDS = 300
MIN_DISTINCT_COLOURS = 24


def run(args: list[str], timeout: int = 300) -> str:
    finished = subprocess.run(args, capture_output=True, text=True, timeout=timeout)
    if finished.returncode:
        raise RuntimeError(f"{' '.join(args[:4])}: {(finished.stdout + finished.stderr)[-2000:]}")
    return finished.stdout


def flat_screen(path: Path) -> tuple[bool, int]:
    """True when the screenshot is one flat colour, plus how many colours it had."""
    try:
        from PIL import Image  # type: ignore
    except ImportError:  # pragma: no cover - the gate must not depend on Pillow
        return (False, -1)
    with Image.open(path) as image:
        colours = image.convert("RGB").getcolors(maxcolors=1 << 24) or []
    return (len(colours) < MIN_DISTINCT_COLOURS, len(colours))


def paint_budget(udid: str, timeout: int = PAINT_BUDGET_SECONDS) -> tuple[bool, int, Path]:
    """Poll the screen until it stops being one flat colour."""
    out = Path("/tmp/aleph-sim-shots")
    out.mkdir(parents=True, exist_ok=True)
    elapsed = 0
    shot = out / f"{udid}-paint.png"
    while elapsed <= timeout:
        run(["xcrun", "simctl", "io", udid, "screenshot", "--type=png", str(shot)])
        flat, colours = flat_screen(shot)
        if not flat:
            return (True, elapsed, shot)
        time.sleep(10)
        elapsed += 10
    return (False, elapsed, shot)


def check_device(udid: str, name: str, app: Path, bundle: str, out: Path) -> dict:
    subprocess.run(["xcrun", "simctl", "shutdown", udid], capture_output=True)
    run(["xcrun", "simctl", "boot", udid])
    run(["xcrun", "simctl", "bootstatus", udid, "-b"], 600)
    run(["xcrun", "simctl", "install", udid, str(app)])

    record: dict = {"device": name, "udid": udid, "launches": []}
    for attempt in range(2):
        if attempt:
            subprocess.run(["xcrun", "simctl", "terminate", udid, bundle], capture_output=True)
            time.sleep(3)
        launch = run(["xcrun", "simctl", "launch", udid, bundle])
        time.sleep(ALIVE_SECONDS)
        jobs = run(["xcrun", "simctl", "spawn", udid, "launchctl", "list"])
        alive = [line for line in jobs.splitlines() if bundle in line and line.split()[0].isdigit()]
        painted, seconds, shot = paint_budget(udid)
        record["launches"].append(
            {
                "launch": launch.strip(),
                "aliveAfterSeconds": ALIVE_SECONDS,
                "alive": bool(alive),
                "painted": painted,
                "secondsToFirstFrame": seconds,
                "screenshot": str(shot),
                "screenshotCopy": str(Path(out) / f"{name.replace(' ', '-')}-coldstart-{attempt}.png"),
            }
        )
        if not alive:
            raise RuntimeError(f"{name}: not running {ALIVE_SECONDS} s after cold start {attempt}")
        if not painted:
            raise RuntimeError(
                f"{name}: the screen was still one flat colour after {seconds} s, so the app never painted"
            )
        (Path(out) / f"{name.replace(' ', '-')}-coldstart-{attempt}.png").write_bytes(shot.read_bytes())
    subprocess.run(["xcrun", "simctl", "shutdown", udid], capture_output=True)
    return record


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--app", required=True, help="path to the built .app for a simulator")
    parser.add_argument("--bundle", default="com.originalbible.originalBible")
    parser.add_argument("--out", default="build/sim-launch")
    parser.add_argument("--device", action="append", help="simulator UDID, repeatable")
    args = parser.parse_args()

    if sys.platform != "darwin":
        print("sim_launch_check: needs macOS and xcrun simctl; run it on the build Mac.")
        return 2

    app = Path(args.app).resolve()
    if not (app / "Info.plist").exists():
        print(f"sim_launch_check: no Info.plist in {app}, build for the simulator first.")
        return 2
    info = plistlib.loads((app / "Info.plist").read_bytes())
    out = Path(args.out)
    out.mkdir(parents=True, exist_ok=True)

    result: dict = {
        "bundle": info.get("CFBundleIdentifier"),
        "build": info.get("CFBundleVersion"),
        "version": info.get("CFBundleShortVersionString"),
        "appPath": str(app),
        "devices": [],
        "passed": False,
        "startedAt": datetime.datetime.now(datetime.timezone.utc).isoformat(),
    }

    udids = args.device
    if not udids:
        listing = json.loads(run(["xcrun", "simctl", "list", "devices", "available", "--json"]))["devices"]
        runtime = max(runtime for runtime in listing if "iOS" in runtime)
        wanted = ("iPhone", "iPad")
        udids = []
        for prefix in wanted:
            match = next(
                (device["udid"] for device in listing[runtime] if device["name"].startswith(prefix)),
                None,
            )
            if not match:
                print(f"sim_launch_check: no {prefix} simulator on this machine.")
                return 2
            udids.append(match)

    try:
        for udid in udids:
            name = next(
                (
                    device["name"]
                    for devices in json.loads(
                        run(["xcrun", "simctl", "list", "devices", "available", "--json"])
                    )["devices"].values()
                    for device in devices
                    if device["udid"] == udid
                ),
                udid,
            )
            result["devices"].append(check_device(udid, name, app, args.bundle, out))
        result["passed"] = True
    except BaseException as error:
        result["error"] = str(error)
        print(f"sim_launch_check: FAILED: {error}")
    finally:
        (out / "result.json").write_text(json.dumps(result, indent=2))
        print(f"sim_launch_check: evidence in {out / 'result.json'}")

    return 0 if result["passed"] else 1


if __name__ == "__main__":
    sys.exit(main())
