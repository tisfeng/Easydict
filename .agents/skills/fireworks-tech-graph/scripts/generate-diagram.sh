#!/bin/bash
# SVG Diagram Generation - Validates and exports SVG diagrams with PNG export

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Default values
STYLE="1"
WIDTH="1920"
OUTPUT_DIR="."
VALIDATE=true

# Valid diagram types
VALID_TYPES="architecture|data-flow|flowchart|sequence|comparison|timeline|mind-map|agent|memory|use-case|class|state-machine|er-diagram|network-topology"

usage() {
    cat << USAGE
Usage: $0 [OPTIONS]

Options:
    -t, --type TYPE        Diagram type ($VALID_TYPES)
    -s, --style STYLE      Style number (1-12, default: 1)
    -o, --output PATH      Output path (default: current directory)
    -w, --width WIDTH      PNG width in pixels (default: 1920)
    --no-validate          Skip validation
    -h, --help             Show this help

Examples:
    $0 -t architecture -s 1 -o ./output/arch.svg
    $0 -t class -s 2 -w 2400
    $0 -t sequence -s 6
USAGE
    exit "${1:-0}"
}

# Parse arguments
require_arg() { if [[ $# -lt 2 || "$2" == -* ]]; then echo -e "${RED}Error: $1 requires a value${NC}"; usage 1; fi; }
while [[ $# -gt 0 ]]; do
    case $1 in
        -t|--type)
            require_arg "$@"
            TYPE="$2"
            shift 2
            ;;
        -s|--style)
            require_arg "$@"
            STYLE="$2"
            shift 2
            ;;
        -o|--output)
            require_arg "$@"
            OUTPUT_PATH="$2"
            shift 2
            ;;
        -w|--width)
            require_arg "$@"
            WIDTH="$2"
            shift 2
            ;;
        --no-validate)
            VALIDATE=false
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            usage 1
            ;;
    esac
done

# Check required parameters
if [ -z "${TYPE:-}" ]; then
    echo -e "${RED}Error: Diagram type is required${NC}"
    usage 1
fi

# Validate type
VALID_TYPE=false
for t in architecture data-flow flowchart sequence comparison timeline mind-map agent memory use-case class state-machine er-diagram network-topology; do
    if [ "$TYPE" = "$t" ]; then
        VALID_TYPE=true
        break
    fi
done

if [ "$VALID_TYPE" = false ]; then
    echo -e "${RED}Error: Invalid diagram type '$TYPE'${NC}"
    echo "Valid types: $VALID_TYPES"
    exit 1
fi

if ! [[ "$WIDTH" =~ ^[1-9][0-9]*$ ]]; then
    echo -e "${RED}Error: Width must be a positive integer${NC}"
    exit 1
fi

# Determine output path
if [ -z "${OUTPUT_PATH:-}" ]; then
    BASENAME="${TYPE}-style${STYLE}"
    SVG_FILE="${OUTPUT_DIR}/${BASENAME}.svg"
    PNG_FILE="${OUTPUT_DIR}/${BASENAME}.png"
else
    SVG_FILE="$OUTPUT_PATH"
    PNG_FILE="${OUTPUT_PATH%.svg}.png"
fi

echo -e "${BLUE}Processing ${TYPE} diagram (style ${STYLE})...${NC}"
echo "Output: $SVG_FILE"

# Load style reference
SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STYLE_FILE=$(find "${SKILL_DIR}/references" -maxdepth 1 -type f -name "style-${STYLE}-*.md" | head -n 1)

if [ -z "${STYLE_FILE:-}" ] || [ ! -f "$STYLE_FILE" ]; then
    echo -e "${RED}Error: Style file not found: ${STYLE_FILE}${NC}"
    echo "Available styles: 1-12"
    exit 1
fi

# Note: Actual SVG generation is done by the invoking AI coding agent
# This script provides validation and export only

echo -e "${YELLOW}Note: SVG content generation is handled by Codex or Claude Code${NC}"
echo -e "${YELLOW}This script provides validation and export only${NC}"

# Validate if SVG exists
if [ -f "$SVG_FILE" ]; then
    if [ "$VALIDATE" = true ]; then
        echo -e "\n${BLUE}Validating SVG...${NC}"
        if "${SKILL_DIR}/scripts/validate-svg.sh" "$SVG_FILE"; then
            echo -e "${GREEN}Validation passed${NC}"
        else
            echo -e "${RED}Validation failed${NC}"
            exit 1
        fi
    fi

    # Export PNG
    echo -e "\n${BLUE}Exporting PNG (width: ${WIDTH}px)...${NC}"

    python3 "${SKILL_DIR}/scripts/fireworks.py" export-png "$SVG_FILE" "$PNG_FILE" --width "$WIDTH"

else
    echo -e "${YELLOW}SVG file not found. Generate it first with Codex or Claude Code.${NC}"
    exit 1
fi

echo -e "\n${GREEN}Done${NC}"
