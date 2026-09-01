#!/usr/bin/env bash
# mayhem/test.sh — run the libcheck test binaries built by build.sh; parse their
# per-suite "Checks: N, Failures: F, Errors: E" line; emit a CTRF summary.
set -uo pipefail
[ -n "${SOURCE_DATE_EPOCH:-}" ] || unset SOURCE_DATE_EPOCH
cd "$SRC"

emit_ctrf() {
  local tool="$1" passed="$2" failed="$3" skipped="${4:-0}" pending="${5:-0}" other="${6:-0}"
  local tests=$(( passed + failed + skipped + pending + other ))
  cat > "${CTRF_REPORT:-$SRC/ctrf-report.json}" <<JSON
{
  "results": {
    "tool": { "name": "$tool" },
    "summary": {
      "tests": $tests,
      "passed": $passed,
      "failed": $failed,
      "pending": $pending,
      "skipped": $skipped,
      "other": $other
    }
  }
}
JSON
  printf 'CTRF {"results":{"tool":{"name":"%s"},"summary":{"tests":%d,"passed":%d,"failed":%d,"pending":%d,"skipped":%d,"other":%d}}}\n' \
    "$tool" "$tests" "$passed" "$failed" "$pending" "$skipped" "$other"
  [ "$failed" -eq 0 ] && [ "$passed" -gt 0 ]
}

BINS=(
  /mayhem/tests/test_strl
  /mayhem/tests/test_linked_list
  /mayhem/tests/test_generic_queue
  /mayhem/tests/test_mempool
)

for b in "${BINS[@]}"; do
  [ -x "$b" ] || { echo "test.sh: missing $b — build.sh should have produced it" >&2; emit_ctrf "libcheck" 0 1; exit 1; }
done

total_checks=0; total_failures=0; total_errors=0
for b in "${BINS[@]}"; do
  echo "=== $(basename "$b") ==="
  out="$("$b" 2>&1)" || true
  echo "$out"
  # libcheck prints e.g. "100%: Checks: 12, Failures: 0, Errors: 0"
  line="$(echo "$out" | grep -Eo 'Checks: [0-9]+, Failures: [0-9]+, Errors: [0-9]+' | tail -1)"
  if [ -z "$line" ]; then
    echo "test.sh: $b produced no libcheck summary line" >&2
    total_errors=$(( total_errors + 1 ))
    continue
  fi
  c="$(echo "$line" | sed -E 's/.*Checks: ([0-9]+).*/\1/')"
  f="$(echo "$line" | sed -E 's/.*Failures: ([0-9]+).*/\1/')"
  e="$(echo "$line" | sed -E 's/.*Errors: ([0-9]+).*/\1/')"
  total_checks=$(( total_checks + c ))
  total_failures=$(( total_failures + f ))
  total_errors=$(( total_errors + e ))
done

passed=$(( total_checks - total_failures - total_errors ))
failed=$(( total_failures + total_errors ))

emit_ctrf "libcheck" "$passed" "$failed"
