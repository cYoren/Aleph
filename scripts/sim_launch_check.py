#!/usr/bin/env python3
"""Launch the built app on an iPhone and an iPad simulator, and prove it is alive.

Why this exists: a build that stays in the process list but paints one flat
colour is still a rejection, and "the process is running" says nothing about the
first frame. The 234 MB bundled database unpacks on first launch, so on a
debug simulator build the first frame legitimately takes minutes; what must never
happen is that it never arrives at all.

The app is uninstalled before installing, so the first launch is a real first
launch (no database on disk, the bundled one unpacks). It checks, per device,
twice (cold start each time):
  1. the process is still running 20 s after launch,
  2. the screen paints something other than a single flat colour,

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


class MissingDependency(RuntimeError):
    pass


def flat_screen(path: Path) -> tuple[bool, int]:
    """True when the screenshot is one flat colour, plus how many colours it had.

    A missing Pillow raises: a check that cannot run must never report "painted".
    """
    try:
        from PIL import Image  # type: ignore
    except ImportError as error:  # pragma: no cover - depends on the machine
        raise MissingDependency(
            "Pillow is required to tell a blank screen from a painted one: "
            "python3 -m pip install pillow"
        ) from error
    with Image.open(path) as image:
        colours = image.convert("RGB").getcolors(maxcolors=1 << 24)
    if colours is None:
        # More colours than maxcolors cannot be a flat screen.
        return (False, 1 << 24)
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
    # A device already booted (or still shutting down) answers boot with an
    # error that does not matter; bootstatus is the authority.
    subprocess.run(["xcrun", "simctl", "boot", udid], capture_output=True)
    run(["xcrun", "simctl", "bootstatus", udid, "-b"], 600)
    # Uninstall first: a real first launch has no database and must unpack the
    # bundled one, which is the slow path a reviewer's device takes. Installing
    # over an existing copy would only ever test the second launch.
    subprocess.run(["xcrun", "simctl", "uninstall", udid, bundle], capture_output=True)
    run(["xcrun", "simctl", "install", udid, str(app)])

    record: dict = {"device": name, "udid": udid, "launches": []}
    try:
        for attempt in range(2):
            if attempt:
                subprocess.run(["xcrun", "simctl", "terminate", udid, bundle], capture_output=True)
                time.sleep(3)
            launch = run(["xcrun", "simctl", "launch", udid, bundle])
            time.sleep(ALIVE_SECONDS)
            jobs = run(["xcrun", "simctl", "spawn", udid, "launchctl", "list"])
            alive = [line for line in jobs.splitlines() if bundle in line and line.split()[0].isdigit()]
            painted, seconds, shot = paint_budget(udid)
            copy = Path(out) / f"{name.replace(' ', '-')}-coldstart-{attempt}.png"
            # Copy the evidence first: a failing run is the one worth looking at.
            copy.write_bytes(shot.read_bytes())
            record["launches"].append(
                {
                    "launch": launch.strip(),
                    "aliveAfterSeconds": ALIVE_SECONDS,
                    "alive": bool(alive),
                    "painted": painted,
                    "secondsToFirstFrame": seconds,
                    "screenshot": str(copy),
                }
            )
            if not alive:
                raise RuntimeError(f"{name}: not running {ALIVE_SECONDS} s after cold start {attempt}")
            if not painted:
                raise RuntimeError(
                    f"{name}: the screen stayed one flat colour for {seconds} s, so the app never painted"
                )
    finally:
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

    listing = json.loads(run(["xcrun", "simctl", "list", "devices", "available", "--json"]))["devices"]
    by_udid = {device["udid"]: device for devices in listing.values() for device in devices}

    udids = args.device or []
    if not udids:
        # Numeric, not lexicographic: "iOS-9-0" would beat "iOS-26-0" as a string.
        def major(runtime_id: str) -> tuple[int, ...]:
            parts = runtime_id.rsplit("-", 3)
            numbers = [p for p in parts if p.isdigit()]
            return tuple(int(p) for p in numbers) or (0,)

        # Newest runtime per device family: a machine can have the iPhone on one
        # iOS runtime and the iPad on another.
        for prefix in ("iPhone", "iPad"):
            runtimes = [
                runtime
                for runtime, devices in listing.items()
                if "iOS" in runtime
                and any(device["name"].startswith(prefix) for device in devices)
            ]
            if not runtimes:
                families = sorted(
                    {device["name"].split()[0] for devices in listing.values() for device in devices}
                )
                print(
                    f"sim_launch_check: no {prefix} simulator on this machine "
                    f"(available families: {families})."
                )
                return 2
            runtime = max(runtimes, key=major)
            match = next(
                device["udid"] for device in listing[runtime] if device["name"].startswith(prefix)
            )
            udids.append(match)

    # App Review runs both, so a pass on two iPhones is not a pass.
    names = [by_udid.get(udid, {}).get("name", "") for udid in udids]
    if not any(name.startswith("iPhone") for name in names) or not any(
        name.startswith("iPad") for name in names
    ):
        print(f"sim_launch_check: needs an iPhone and an iPad, got {names}")
        return 2

    try:
        for udid in udids:
            name = by_udid.get(udid, {}).get("name", udid)
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
