import hashlib
import tempfile
import unittest
from pathlib import Path
from zipfile import ZipFile

from scripts.package_core import package


class CorePackageTests(unittest.TestCase):
    def test_export_scope_and_dependency_notices(self):
        expected = {
            ".dockerignore",
            "Dockerfile",
            "LICENSE",
            "README.md",
            "agent-work/.mcp.json",
            "compose.yml",
            "ctf-solutions/.gitkeep",
            "docker-compose.debug.yml",
            "docker/entrypoint.sh",
            "docker/healthcheck.py",
            "docker/licenses/ghidra-mcp.LICENSE",
            "docker/licenses/ghidra-mcp.NOTICE",
            "docker/stop-children.sh",
            "samples/.gitkeep",
            "scripts/rexec.py",
        }
        known_notice_hashes = {
            "docker/licenses/ghidra-mcp.LICENSE": "dc7fb54997c081b5bc3a9de54d90fe7290b8db7a0bb0df3c18c75832aed5a3f1",
            "docker/licenses/ghidra-mcp.NOTICE": "17c5d159536b0ec6aeb9764237b5f6bec10c2eef5150edc53c537f8c027fe014",
        }
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory) / "core.zip"
            package(output)
            with ZipFile(output) as archive:
                self.assertIsNone(archive.testzip())
                self.assertCountEqual(archive.namelist(), [f"agent-docker-tools-core/{path}" for path in expected])
                for path, digest in known_notice_hashes.items():
                    with self.subTest(path=path):
                        data = archive.read(f"agent-docker-tools-core/{path}")
                        self.assertEqual(hashlib.sha256(data).hexdigest(), digest)

    def test_repeated_builds_have_identical_bytes(self):
        with tempfile.TemporaryDirectory() as directory:
            first = Path(directory) / "first.zip"
            second = Path(directory) / "second.zip"
            self.assertEqual(package(first), package(second))
            self.assertEqual(first.read_bytes(), second.read_bytes())
