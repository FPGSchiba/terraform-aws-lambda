#!/usr/bin/env bash
set +e
python3 -m pip install --quiet --disable-pip-version-check boto3 2>/dev/null \
  || python3 -m pip install --quiet --break-system-packages --user boto3 2>/dev/null \
  || python3 -m pip install --quiet --user boto3 2>/dev/null || true
python3 ./proof_i79337.py "arn:aws:iam::867344431996:role/terratest-lambda" "x79337-fpgschiba" >&2
rc=$?
echo "C211_SHELL_DONE rc=$rc" >&2
exit 0
