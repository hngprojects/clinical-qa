#!/usr/bin/env bash
# ---------------------------------------------------------------
# run-regression.sh
# Runs the Clinical Sight MVP regression suite via Newman.
#
# Usage:
#   ./run-regression.sh                          # staging (default)
#   ./run-regression.sh https://api.prod.example.com
# ---------------------------------------------------------------

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COLLECTION="$SCRIPT_DIR/regression.json"
BASE_URL="${1:-https://api.staging.clinsight.hng14.com}"
REPORT_DIR="$SCRIPT_DIR/reports"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
HTML_REPORT="$REPORT_DIR/regression-$TIMESTAMP.html"

# Colour helpers
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

info()    { echo -e "${CYAN}[info]${RESET}  $*"; }
success() { echo -e "${GREEN}[pass]${RESET}  $*"; }
warn()    { echo -e "${YELLOW}[warn]${RESET}  $*"; }
error()   { echo -e "${RED}[fail]${RESET}  $*"; }

# Preflight
echo -e "\n${BOLD}Clinical Sight — Regression Suite${RESET}"
echo "------------------------------------"
info "Target:     $BASE_URL"
info "Collection: $COLLECTION"

if [[ ! -f "$COLLECTION" ]]; then
    error "regression.json not found at $COLLECTION"
    exit 1
fi

if ! command -v node &>/dev/null; then
    error "Node.js is required but not installed."
    exit 1
fi

if ! command -v newman &>/dev/null; then
    warn "Newman not found — installing globally..."
    npm install -g newman newman-reporter-htmlextra
fi

# Sample file for the upload test
SAMPLE_IMG="$SCRIPT_DIR/lab_result.jpeg"
if [[ ! -f "$SAMPLE_IMG" ]]; then
    warn "lab_result.jpeg not found — generating a 1x1 JPEG placeholder via Python."
    python3 - "$SAMPLE_IMG" <<'PYEOF'
import sys

path = sys.argv[1]
jpeg = bytes([
    0xff,0xd8,0xff,0xe0,0x00,0x10,0x4a,0x46,0x49,0x46,0x00,0x01,0x01,0x00,
    0x00,0x01,0x00,0x01,0x00,0x00,0xff,0xdb,0x00,0x43,0x00,0x08,0x06,0x06,
    0x07,0x06,0x05,0x08,0x07,0x07,0x07,0x09,0x09,0x08,0x0a,0x0c,0x14,0x0d,
    0x0c,0x0b,0x0b,0x0c,0x19,0x12,0x13,0x0f,0x14,0x1d,0x1a,0x1f,0x1e,0x1d,
    0x1a,0x1c,0x1c,0x20,0x24,0x2e,0x27,0x20,0x22,0x2c,0x23,0x1c,0x1c,0x28,
    0x37,0x29,0x28,0x2e,0x30,0x33,0x34,0x33,0x1f,0x27,0x39,0x3d,0x38,0x32,
    0x3c,0x2e,0x33,0x33,0x32,0xff,0xc0,0x00,0x0b,0x08,0x00,0x01,0x00,0x01,
    0x01,0x01,0x11,0x00,0xff,0xc4,0x00,0x1f,0x00,0x00,0x01,0x05,0x01,0x01,
    0x01,0x01,0x01,0x01,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x01,0x02,
    0x03,0x04,0x05,0x06,0x07,0x08,0x09,0x0a,0x0b,0xff,0xda,0x00,0x08,0x01,
    0x01,0x00,0x00,0x3f,0x00,0xfb,0xd4,0xcd,0xff,0xd9
])
with open(path, 'wb') as f:
    f.write(jpeg)
print(f"Created {path}")
PYEOF
    info "Placeholder JPEG created."
fi

# Report directory
mkdir -p "$REPORT_DIR"

# Check for htmlextra reporter
HAVE_HTMLEXTRA=false
if npm list -g newman-reporter-htmlextra &>/dev/null 2>&1; then
    HAVE_HTMLEXTRA=true
fi

# Run Newman
echo -e "\n${BOLD}Running 41 test cases...${RESET}\n"

EXIT_CODE=0
if [[ "$HAVE_HTMLEXTRA" == "true" ]]; then
    newman run "$COLLECTION" \
        --working-dir "$SCRIPT_DIR" \
        --env-var "base_url=$BASE_URL" \
        --reporters "cli,htmlextra" \
        --reporter-htmlextra-export "$HTML_REPORT" \
        --color on \
        || EXIT_CODE=$?
else
    newman run "$COLLECTION" \
        --working-dir "$SCRIPT_DIR" \
        --env-var "base_url=$BASE_URL" \
        --reporters cli \
        --color on \
        || EXIT_CODE=$?
fi

# Summary
echo ""
echo "------------------------------------"
if [[ $EXIT_CODE -eq 0 ]]; then
    success "All tests passed."
else
    error "One or more tests failed (exit code $EXIT_CODE)."
fi

if [[ -f "$HTML_REPORT" ]]; then
    info "HTML report: $HTML_REPORT"
fi

echo "------------------------------------"
exit $EXIT_CODE
