#!/bin/bash
# SVG Validation Script
# Checks SVG syntax and reports detailed errors

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ $# -eq 0 ]; then
    echo "Usage: $0 <svg-file>"
    exit 1
fi

SVG_FILE="$1"

if [ ! -f "$SVG_FILE" ]; then
    echo -e "${RED}Error: File not found: $SVG_FILE${NC}"
    exit 1
fi

echo "Validating SVG: $SVG_FILE"
echo "----------------------------------------"

FAILURES=0

# Check 0: XML structure and attribute syntax
echo -n "Checking XML structure... "
if XML_ERR=$(python3 "${SCRIPT_DIR}/validate_svg.py" "$SVG_FILE" --check xml 2>&1); then
    echo -e "${GREEN}✓ Pass${NC}"
else
    echo -e "${RED}✗ Fail${NC}"
    echo "$XML_ERR"
    FAILURES=$((FAILURES + 1))
fi

# Check 1: Marker references
echo -n "Checking marker references... "
if MARKER_ERR=$(python3 "${SCRIPT_DIR}/validate_svg.py" "$SVG_FILE" --check markers 2>&1); then
    echo -e "${GREEN}✓ Pass${NC}"
else
    echo -e "${RED}✗ Fail${NC}"
    echo "$MARKER_ERR"
    FAILURES=$((FAILURES + 1))
fi

# Check 2: Arrow-component collision
echo -n "Checking arrow collisions... "
set +e
COLLISION_ERR=$(python3 "${SCRIPT_DIR}/validate_svg.py" "$SVG_FILE" --check collisions 2>&1)
COLLISION_EXIT=$?
set -e

if [ "$COLLISION_EXIT" -eq 0 ]; then
    echo -e "${GREEN}✓ Pass${NC}"
else
    echo -e "${RED}✗ Fail${NC}"
    echo "$COLLISION_ERR" | sed -n '1,8p'
    FAILURES=$((FAILURES + 1))
fi

# Check 3: semantic geometry contract for generated artifacts
echo -n "Checking semantic geometry... "
if GEOMETRY_ERR=$(python3 "${SCRIPT_DIR}/validate_svg.py" "$SVG_FILE" --check geometry 2>&1); then
    echo -e "${GREEN}✓ Pass${NC}"
else
    echo -e "${RED}✗ Fail${NC}"
    echo "$GEOMETRY_ERR" | sed -n '1,12p'
    FAILURES=$((FAILURES + 1))
fi

# Check 4: composition-quality budget
echo -n "Checking composition quality... "
if COMPOSITION_ERR=$(python3 "${SCRIPT_DIR}/validate_svg.py" "$SVG_FILE" --check composition 2>&1); then
    echo -e "${GREEN}✓ Pass${NC}"
else
    echo -e "${RED}✗ Fail${NC}"
    echo "$COMPOSITION_ERR" | sed -n '1,12p'
    FAILURES=$((FAILURES + 1))
fi

# Check 5: render validation (cairosvg preferred, rsvg-convert fallback)
echo -n "Running render validation... "
RENDER_OK=false
RENDER_TOOL=""
RENDER_ERR=""
RENDER_OUTPUT=$(mktemp "${TMPDIR:-/tmp}/fireworks-tech-graph.XXXXXX")
trap 'rm -f "$RENDER_OUTPUT"' EXIT

if python3 -c "import cairosvg" 2>/dev/null; then
    RENDER_TOOL="cairosvg"
    if RENDER_ERR=$(python3 -c "import sys, cairosvg; cairosvg.svg2png(url=sys.argv[1], write_to=sys.argv[2])" "$SVG_FILE" "$RENDER_OUTPUT" 2>&1); then
        RENDER_OK=true
    fi
elif command -v rsvg-convert &> /dev/null; then
    RENDER_TOOL="rsvg-convert"
    if RENDER_ERR=$(rsvg-convert "$SVG_FILE" -o "$RENDER_OUTPUT" 2>&1); then
        RENDER_OK=true
    fi
fi

if [ "$RENDER_OK" = true ]; then
    echo -e "${GREEN}✓ Pass${NC} (via ${RENDER_TOOL})"
    rm -f "$RENDER_OUTPUT"
elif [ -n "$RENDER_TOOL" ]; then
    echo -e "${RED}✗ Fail${NC} (via ${RENDER_TOOL})"
    echo "${RENDER_TOOL} error:"
    echo "$RENDER_ERR"
    FAILURES=$((FAILURES + 1))
else
    echo -e "${RED}✗ Fail${NC} (no renderer found — install with: python3 -m pip install cairosvg)"
    FAILURES=$((FAILURES + 1))
fi

echo "----------------------------------------"
if [ "$FAILURES" -eq 0 ]; then
    echo "Validation complete"
    exit 0
fi

echo -e "${RED}Validation failed (${FAILURES} error(s))${NC}"
exit 1
