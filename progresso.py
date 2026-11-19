"""Keep the latest offline Ridge Racer 2 session alongside its memory card."""
import os
from pathlib import Path
import re
import select
import struct
import subprocess
import sys
import tempfile
import time

PROGRESS = Path("progress")
STATES = Path("profile-states")
CARD = Path("profile/PSP/SAVEDATA/UCES00422/000/DATA.BIN")
RESUME = PROGRESS / "retomar.state"
EXIT = PROGRESS / "saida.state"
CHECKPOINT = PROGRESS / "intervalo.sgs"
INTERVAL = 60


def valid_raw(path):
    with path.open("rb") as stream:
        header = stream.read(124)
        return (len(header) == 124 and header.startswith(b"NPSP\x01\0\0\0UCES00422\0")
                and 124 + struct.unpack_from("<I", header, 112)[0] == path.stat().st_size)


def unpack(source, output):
    # Nimbus player states have a build identifier followed by one zstd frame.
    with source.open("rb", buffering=0) as stream:
        if stream.read(4) != b"NMS1":
            raise ValueError("invalid player state")
        length, = struct.unpack("<I", stream.read(4))
        if length > 4096 or b"console PSP; game UCES00422;" not in stream.read(length):
            raise ValueError("unexpected game")
        subprocess.run(["zstd", "-qdc"], stdin=stream, stdout=output, check=True)


def prepare():
    candidates = [p for p in (EXIT, CHECKPOINT, RESUME) if p.is_file()]
    card_time = CARD.stat().st_mtime_ns if CARD.exists() else 0
    for src in sorted(candidates, key=lambda p: p.stat().st_mtime_ns, reverse=True):
        if src.stat().st_mtime_ns < card_time:
            break
        try:
            if src == CHECKPOINT:
                with tempfile.NamedTemporaryFile(dir=PROGRESS, delete=False) as out:
                    tmp = Path(out.name)
                    try:
                        unpack(src, out)
                        out.flush()
                        os.fsync(out.fileno())
                        if not valid_raw(tmp):
                            raise ValueError("incomplete checkpoint")
                        os.utime(tmp, ns=(src.stat().st_atime_ns, src.stat().st_mtime_ns))
                        tmp.replace(RESUME)
                    finally:
                        tmp.unlink(missing_ok=True)
            else:
                if not valid_raw(src):
                    raise ValueError("incomplete session")
                if src == EXIT:
                    src.replace(RESUME)
            print(RESUME.resolve())
            return
        except (OSError, ValueError, struct.error, subprocess.CalledProcessError) as error:
            print(f"{src}: {error}", file=sys.stderr)


def checkpoint(window):
    status = STATES / ".state-status"
    before = status.read_bytes() if status.exists() else b""
    for event in ("keydown", "keyup"):
        subprocess.run(["xdotool", event, "--window", window, "F5"], check=True)
        if event == "keydown":
            time.sleep(0.12)
    for _ in range(30):
        time.sleep(0.1)
        data = status.read_bytes() if status.exists() else b""
        match = re.fullmatch(rb"[\d.]+ saved (\d{8}-\d{6}\.sgs)\s*", data)
        if data == before or not match:
            continue
        new = STATES / match[1].decode("ascii")
        if not new.is_file():
            continue
        # A hard link keeps this completed checkpoint even if the menu deletes it.
        # Remove only the previous automatic file, identified by its inode.
        previous = CHECKPOINT.stat().st_ino if CHECKPOINT.exists() else None
        tmp = PROGRESS / ".intervalo.sgs"
        tmp.unlink(missing_ok=True)
        os.link(new, tmp)
        tmp.replace(CHECKPOINT)
        for old in STATES.glob("*.sgs"):
            if old != new and old.stat().st_ino == previous:
                old.unlink()
        return


def watch(pid):
    poller = select.poll()
    fd = os.pidfd_open(pid)
    poller.register(fd, select.POLLIN)
    while not poller.poll(INTERVAL * 1000):
        try:
            found = subprocess.run(["xdotool", "search", "--onlyvisible", "--all",
                                    "--pid", str(pid), "--name", "^Nimbus - Ridge Racer 2$"],
                                   capture_output=True, text=True)
            if found.stdout.strip():
                checkpoint(found.stdout.splitlines()[0])
        except (OSError, subprocess.CalledProcessError) as error:
            print(f"Checkpoint: {error}", file=sys.stderr, flush=True)


if __name__ == "__main__":
    if sys.argv[1] == "prepare":
        prepare()
    elif sys.argv[1] == "watch":
        watch(int(sys.argv[2]))
