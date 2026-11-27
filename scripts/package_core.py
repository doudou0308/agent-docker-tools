"""Assemble the standalone core source archive."""

import argparse
import hashlib
import os
from pathlib import Path
from tempfile import NamedTemporaryFile
from zipfile import ZIP_DEFLATED, ZipFile, ZipInfo


ROOT = Path(__file__).resolve().parents[1]
ARCHIVE_ROOT = "agent-docker-tools-core"
FILES = {
    ".dockerignore": ".dockerignore",
    "Dockerfile": "Dockerfile",
    "LICENSE": "LICENSE",
    "README.md": "docs/core-release.md",
    "agent-work/.mcp.json": "agent-work/.mcp.json",
    "compose.yml": "docker-compose.yml",
    "docker-compose.debug.yml": "docker-compose.debug.yml",
    "docker/entrypoint.sh": "docker/entrypoint.sh",
    "docker/healthcheck.py": "docker/healthcheck.py",
    "docker/licenses/ghidra-mcp.LICENSE": "docker/licenses/ghidra-mcp.LICENSE",
    "docker/licenses/ghidra-mcp.NOTICE": "docker/licenses/ghidra-mcp.NOTICE",
    "docker/stop-children.sh": "docker/stop-children.sh",
    "scripts/rexec.py": "scripts/rexec.py",
}


def package(output: Path) -> str:
    contents = {
        destination: (ROOT / source).read_bytes().replace(b"\r\n", b"\n")
        for destination, source in FILES.items()
    }
    for directory in ("samples", "ctf-solutions"):
        contents[f"{directory}/.gitkeep"] = b""

    output.parent.mkdir(parents=True, exist_ok=True)
    with NamedTemporaryFile(dir=output.parent, prefix=f".{output.name}.", delete=False) as handle:
        temporary = Path(handle.name)
    try:
        with ZipFile(temporary, "w") as archive:
            for name, content in sorted(contents.items()):
                entry = ZipInfo(f"{ARCHIVE_ROOT}/{name}")
                entry.create_system = 3
                entry.external_attr = 0o100644 << 16
                archive.writestr(entry, content, compress_type=ZIP_DEFLATED, compresslevel=9)
        checksum = hashlib.sha256(temporary.read_bytes()).hexdigest()
        os.replace(temporary, output)
    finally:
        temporary.unlink(missing_ok=True)
    return checksum


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("output", type=Path, help="path to the source ZIP")
    args = parser.parse_args()
    if args.output.suffix.lower() != ".zip":
        parser.error("output must have a .zip extension")
    print(f"{package(args.output)}  {args.output.name}")
