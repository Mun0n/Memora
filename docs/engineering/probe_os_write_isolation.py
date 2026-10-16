"""Non-agent experiment: OS write restrictions against disposable fixtures."""
import json
import pathlib
import subprocess
import sys
import tempfile

root = pathlib.Path(tempfile.mkdtemp(prefix="memora-isolation-probe-")).resolve()
allowed = root / "ui"
protected = root / "domain"
allowed.mkdir()
protected.mkdir()
original = protected / "rules.txt"
original.write_text("original\n")
(allowed / "escape").symlink_to(protected, target_is_directory=True)
profile = root / "profile.sb"
profile.write_text('(version 1)\n(allow default)\n(deny network*)\n'
                   '(deny file-write*)\n'
                   f'(allow file-write* (subpath {json.dumps(str(allowed))}))\n'
                   '(allow file-write* (literal "/dev/null"))\n')
cases = [
    ("allowed_write", 'printf changed > "$1/ok.txt"', allowed, True),
    ("absolute_forbidden", 'printf changed > "$1/rules.txt"', protected, False),
    ("parent_escape", 'printf changed > "$1/../domain/rules.txt"', allowed, False),
    ("symlink_escape", 'printf changed > "$1/escape/rules.txt"', allowed, False),
    ("child_shell", '/bin/sh -c \'printf changed > "$1/rules.txt"\' child "$1"', protected, False),
    ("delete", '/bin/rm "$1/rules.txt"', protected, False),
    ("rename", '/bin/mv "$1/rules.txt" "$1/moved.txt"', protected, False),
]
results = []
for name, script, path, should_succeed in cases:
    proc = subprocess.run(["/usr/bin/sandbox-exec", "-f", str(profile),
                           "/bin/sh", "-c", script, "probe", str(path)],
                          capture_output=True, text=True, timeout=15)
    intact = original.exists() and original.read_text() == "original\n"
    setup_failed = "sandbox-exec:" in proc.stderr
    passed = (proc.returncode == 0) == should_succeed and intact and not setup_failed
    if should_succeed:
        passed = passed and (allowed / "ok.txt").exists() and (allowed / "ok.txt").read_text() == "changed"
    results.append(dict(case=name, exit=proc.returncode, passed=passed,
                        original_intact=intact, stderr=proc.stderr.strip()))
report = dict(directory=str(root), mechanism="sandbox-exec OS write policy",
              agent_launched=False, results=results)
(root / "evidence.json").write_text(json.dumps(report, indent=2) + "\n")
print(json.dumps(report, indent=2))
sys.exit(0 if all(r["passed"] for r in results) else 1)
