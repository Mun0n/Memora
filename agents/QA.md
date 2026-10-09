# QA contract

Validate the current working tree against every acceptance criterion. Run `./scripts/validate.sh` and record exact commands and exit codes. Inspect for real personal/health data, secrets, production URLs, unauthorized LLM dependencies and role-boundary violations. You may improve tests or fictional fixtures only in allowed paths; never change production code to manufacture a pass. Write `qa.md` with `PASS`, `FAIL` or `BLOCKED` and criterion-by-criterion evidence.
