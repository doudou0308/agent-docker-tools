import contextlib
import io
import runpy
import subprocess
import sys
import unittest
from concurrent.futures import ThreadPoolExecutor
from unittest.mock import patch

from scripts import rexec


class RexecTests(unittest.TestCase):
    @patch("scripts.rexec.subprocess.run")
    def test_long_output_runs_once(self, execute):
        execute.return_value = subprocess.CompletedProcess([], 0, "x" * 6000, "")
        self.assertEqual(rexec.sh("printf example"), "x" * 6000)
        execute.assert_called_once()

    @patch("scripts.rexec.subprocess.run")
    def test_long_command_retains_failure(self, execute):
        command = "true; " * 80 + "exit 7"
        execute.return_value = subprocess.CompletedProcess([], 7, "output", "error")
        result = rexec.run(command, "/root/path with spaces")
        self.assertEqual((result.returncode, result.stdout, result.stderr), (7, "output", "error"))
        execute.assert_called_once_with(
            ["docker", "exec", "-w", "/root/path with spaces", rexec.CONTAINER, "bash", "-c", command],
            capture_output=True, text=True, timeout=300,
        )

    @patch("scripts.rexec.subprocess.run", side_effect=subprocess.TimeoutExpired([], 300))
    def test_timeout(self, execute):
        self.assertIn("TIMEOUT", rexec.sh("sleep 301"))
        execute.assert_called_once()

    @patch("scripts.rexec.subprocess.run")
    def test_concurrent_calls_capture_their_own_output(self, execute):
        execute.side_effect = lambda args, **_: subprocess.CompletedProcess(args, 0, args[-1] * 6000, "")
        with ThreadPoolExecutor(2) as pool:
            self.assertEqual(list(pool.map(rexec.sh, ["a", "b"])), ["a" * 6000, "b" * 6000])
        self.assertEqual(execute.call_count, 2)

    @patch("subprocess.run")
    def test_copy_cli_reports_failure_on_stderr(self, execute):
        execute.return_value = subprocess.CompletedProcess([], 7, "", "permission denied")
        for mode in ("cp_to", "cp_from"):
            with self.subTest(mode=mode):
                output, error = io.StringIO(), io.StringIO()
                with patch.object(sys, "argv", [rexec.__file__, mode, "sample.txt"]), \
                     contextlib.redirect_stdout(output), contextlib.redirect_stderr(error):
                    with self.assertRaises(SystemExit) as exited:
                        runpy.run_path(rexec.__file__, run_name="__main__")
                self.assertEqual(exited.exception.code, 7)
                self.assertEqual(output.getvalue(), "")
                self.assertIn("permission denied", error.getvalue())

    @patch("subprocess.run")
    def test_copy_python_api_keeps_text_results(self, execute):
        execute.return_value = subprocess.CompletedProcess([], 0, "", "")
        self.assertEqual(rexec.cp_to("sample.txt"), "[rexec] Copied sample.txt -> /root/sample.txt")
        self.assertEqual(rexec.cp_from("/root/sample.txt"), "[rexec] Copied /root/sample.txt -> .")
        execute.return_value = subprocess.CompletedProcess([], 1, "", "permission denied")
        self.assertEqual(rexec.cp_to("sample.txt"), "[rexec] CP ERROR: permission denied")
        self.assertEqual(rexec.cp_from("/root/sample.txt"), "[rexec] CP ERROR: permission denied")
