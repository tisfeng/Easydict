#!/bin/bash
# Batch Test Script
# Renders regression fixtures, validates SVGs, and exports PNGs

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_DIR="${TEST_OUTPUT_DIR:-${SKILL_DIR}/test-output}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

echo -e "${BLUE}=== Fireworks Tech Graph - Batch Test ===${NC}"
echo "Test directory: $TEST_DIR"
echo "Timestamp: $TIMESTAMP"
echo ""

# Create test directory
mkdir -p "$TEST_DIR"

# Test configuration
STYLES=(1 2 3 4 5 6 7 8 9 10 11 12)
STYLE_NAMES=("Flat Icon" "Dark Terminal" "Blueprint" "Notion Clean" "Glassmorphism" "Claude Official" "OpenAI" "Dark Luxury" "C4 Review Canvas" "Cloud Fabric" "Event Transit" "Ops Pulse")
PNG_WIDTH=1920

export_png() {
    local svg_file="$1"
    local png_file="$2"

    python3 "${SKILL_DIR}/scripts/fireworks.py" export-png "$svg_file" "$png_file" --width "$PNG_WIDTH" >/dev/null

}

# Summary counters
TOTAL=0
PASSED=0
FAILED=0

FIXTURES_DIR="${SKILL_DIR}/fixtures"

echo -e "${BLUE}Testing all styles...${NC}"
echo "----------------------------------------"

for i in "${!STYLES[@]}"; do
    STYLE="${STYLES[$i]}"
    STYLE_NAME="${STYLE_NAMES[$i]}"

    echo -e "\n${YELLOW}Style $STYLE: $STYLE_NAME${NC}"

    # Check if style reference exists
    STYLE_FILE=$(find "${SKILL_DIR}/references" -maxdepth 1 -type f -name "style-${STYLE}-*.md" | head -n 1)
    if [ -z "${STYLE_FILE:-}" ] || [ ! -f "$STYLE_FILE" ]; then
        echo -e "${RED}✗ Style file not found: $STYLE_FILE${NC}"
        FAILED=$((FAILED + 1))
        TOTAL=$((TOTAL + 1))
        continue
    fi

    echo -e "${GREEN}✓ Style file found${NC}"

    if [ ! -d "$FIXTURES_DIR" ]; then
        echo -e "${RED}✗ Fixtures directory not found: $FIXTURES_DIR${NC}"
        FAILED=$((FAILED + 1))
        TOTAL=$((TOTAL + 1))
        continue
    fi

    FIXTURE_FILES=$(find "$FIXTURES_DIR" -maxdepth 1 -type f -name "*.json" | sort || true)
    MATCHED_FIXTURES=()
    MATCHED_COUNT=0
    for FIXTURE in $FIXTURE_FILES; do
        FIXTURE_STYLE=$(python3 - "$FIXTURE" <<'PY'
import json
import sys
from pathlib import Path
data = json.loads(Path(sys.argv[1]).read_text(encoding='utf-8'))
print(data.get("style", ""))
PY
)
        if [ "$FIXTURE_STYLE" = "$STYLE" ]; then
            MATCHED_FIXTURES+=("$FIXTURE")
            MATCHED_COUNT=$((MATCHED_COUNT + 1))
        fi
    done

    STATIC_FIXTURE_FILES=$(find "$FIXTURES_DIR" -maxdepth 1 -type f -name "*-style${STYLE}.svg" | sort || true)
    if [ "$MATCHED_COUNT" -eq 0 ] && [ -z "$STATIC_FIXTURE_FILES" ]; then
        echo -e "${RED}✗ No regression fixtures found for style $STYLE${NC}"
        FAILED=$((FAILED + 1))
        TOTAL=$((TOTAL + 1))
        continue
    fi

    # Render, validate, and export each fixture
    if [ "$MATCHED_COUNT" -gt 0 ]; then
      for FIXTURE in "${MATCHED_FIXTURES[@]}"; do
        BASENAME=$(basename "$FIXTURE" .json)
        SVG_FILE="${TEST_DIR}/${BASENAME}_${TIMESTAMP}.svg"
        PNG_FILE="${TEST_DIR}/${BASENAME}_${TIMESTAMP}.png"
        TEMPLATE_TYPE=$(python3 - "$FIXTURE" <<'PY'
import json
import sys
from pathlib import Path
data = json.loads(Path(sys.argv[1]).read_text(encoding='utf-8'))
print(data.get("template_type", "architecture"))
PY
)

        echo -n "  Rendering $BASENAME... "
        TOTAL=$((TOTAL + 1))

        if python3 "${SKILL_DIR}/scripts/generate-from-template.py" "$TEMPLATE_TYPE" "$SVG_FILE" "$(cat "$FIXTURE")" > /dev/null 2>&1 \
            && "${SKILL_DIR}/scripts/validate-svg.sh" "$SVG_FILE" > /dev/null 2>&1; then
            # Prefer CairoSVG (best CSS support); fall back to rsvg-convert.
            if export_png "$SVG_FILE" "$PNG_FILE"; then
                PNG_SIZE=$(du -h "$PNG_FILE" | cut -f1)
                echo -e "${GREEN}✓ Pass${NC} (${PNG_SIZE})"
                PASSED=$((PASSED + 1))
            else
                echo -e "${RED}✗ Fail${NC} (PNG export failed)"
                FAILED=$((FAILED + 1))
            fi
        else
            echo -e "${RED}✗ Fail${NC}"
            FAILED=$((FAILED + 1))
            if [ -f "$SVG_FILE" ]; then
                "${SKILL_DIR}/scripts/validate-svg.sh" "$SVG_FILE" 2>&1 | grep -E "✗|Error" | sed 's/^/    /' || true
            fi
        fi
      done
    fi

    # AI-authored styles use static SVG fixtures because the template generator
    # intentionally does not own their visual composition.
    for FIXTURE in $STATIC_FIXTURE_FILES; do
        BASENAME=$(basename "$FIXTURE" .svg)
        SVG_FILE="${TEST_DIR}/${BASENAME}_${TIMESTAMP}.svg"
        PNG_FILE="${TEST_DIR}/${BASENAME}_${TIMESTAMP}.png"
        echo -n "  Validating $BASENAME... "
        TOTAL=$((TOTAL + 1))
        cp "$FIXTURE" "$SVG_FILE"

        if "${SKILL_DIR}/scripts/validate-svg.sh" "$SVG_FILE" > /dev/null 2>&1; then
            if export_png "$SVG_FILE" "$PNG_FILE"; then
                PNG_SIZE=$(du -h "$PNG_FILE" | cut -f1)
                echo -e "${GREEN}✓ Pass${NC} (${PNG_SIZE})"
                PASSED=$((PASSED + 1))
            else
                echo -e "${RED}✗ Fail${NC} (PNG export failed)"
                FAILED=$((FAILED + 1))
            fi
        else
            echo -e "${RED}✗ Fail${NC}"
            FAILED=$((FAILED + 1))
            "${SKILL_DIR}/scripts/validate-svg.sh" "$SVG_FILE" 2>&1 | grep -E "✗|Error|intersects|missing marker" | sed 's/^/    /' || true
        fi
    done
done

# Print summary
echo ""
echo "========================================"
echo -e "${BLUE}Test Summary${NC}"
echo "----------------------------------------"
echo "Total tests: $TOTAL"
echo -e "${GREEN}Passed: $PASSED${NC}"
echo -e "${RED}Failed: $FAILED${NC}"

if [ "$FAILED" -eq 0 ]; then
    echo -e "\n${GREEN}✓ All tests passed!${NC}"
    exit 0
else
    echo -e "\n${RED}✗ Some tests failed${NC}"
    exit 1
fi
