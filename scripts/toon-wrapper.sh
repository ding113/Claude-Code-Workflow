#!/usr/bin/env bash
# TOON Wrapper Script
# Provides jq-like interface for TOON format with backward compatibility for JSON
# Usage: toon-wrapper.sh [encode|decode|convert] [options]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors for output
COLOR_RESET='\033[0m'
COLOR_ERROR='\033[0;31m'
COLOR_INFO='\033[0;36m'

# Check if tsx is available
if ! command -v npx &> /dev/null; then
    echo -e "${COLOR_ERROR}Error: npx not found. Please install Node.js${COLOR_RESET}" >&2
    exit 1
fi

# Main TOON processing function using TypeScript utilities
process_toon() {
    local action="$1"
    local input="$2"
    local options="$3"

    # Create temp script to run TOON utilities
    local temp_script=$(mktemp).ts
    cat > "$temp_script" << EOF
import { encodeTOON, decodeTOON, detectFormat, autoDecode, convertJSONToTOON, convertTOONToJSON } from '$PROJECT_ROOT/src/utils/toon';
import * as fs from 'fs';

const args = process.argv.slice(2);
const action = args[0];
const input = args[1] || '';
const delimiter = args[2] || ',';

async function main() {
  let inputData: string;

  // Read from stdin if no input provided
  if (!input || input === '-') {
    inputData = fs.readFileSync(0, 'utf-8');
  } else if (fs.existsSync(input)) {
    inputData = fs.readFileSync(input, 'utf-8');
  } else {
    inputData = input;
  }

  try {
    let result;

    switch (action) {
      case 'encode':
        const data = JSON.parse(inputData);
        result = encodeTOON(data, { delimiter: delimiter as any });
        break;

      case 'decode':
        result = JSON.stringify(decodeTOON(inputData), null, 2);
        break;

      case 'detect':
        result = detectFormat(inputData);
        break;

      case 'auto':
        result = JSON.stringify(autoDecode(inputData), null, 2);
        break;

      case 'json-to-toon':
        result = convertJSONToTOON(inputData, { delimiter: delimiter as any });
        break;

      case 'toon-to-json':
        result = convertTOONToJSON(inputData);
        break;

      default:
        console.error(`Unknown action: ${action}`);
        process.exit(1);
    }

    console.log(result);
  } catch (error) {
    console.error('Error:', error instanceof Error ? error.message : String(error));
    process.exit(1);
  }
}

main();
EOF

    # Run with tsx
    cd "$PROJECT_ROOT"
    npx tsx "$temp_script" "$action" "$input" "$options" 2>&1
    local exit_code=$?

    rm -f "$temp_script"
    return $exit_code
}

# Show usage
show_usage() {
    cat << EOF
TOON Wrapper - jq-like interface for TOON format

Usage:
  $0 encode [FILE|-]           # Encode JSON to TOON (from file or stdin)
  $0 decode [FILE|-]           # Decode TOON to JSON
  $0 detect [FILE|-]           # Detect format (json/toon/unknown)
  $0 auto [FILE|-]             # Auto-detect and decode
  $0 json-to-toon [FILE|-]     # Convert JSON file to TOON
  $0 toon-to-json [FILE|-]     # Convert TOON file to JSON

Options:
  -d, --delimiter CHAR         # Use delimiter: comma (default), tab, pipe

Examples:
  # Encode JSON to TOON
  cat data.json | $0 encode
  $0 encode data.json

  # Decode TOON to JSON
  cat data.toon | $0 decode

  # Auto-detect and decode
  $0 auto data.txt

  # Convert with tab delimiter
  $0 encode data.json --delimiter tab

EOF
}

# Parse command line arguments
ACTION=""
INPUT=""
DELIMITER=","

while [[ $# -gt 0 ]]; do
    case $1 in
        encode|decode|detect|auto|json-to-toon|toon-to-json)
            ACTION="$1"
            shift
            ;;
        -d|--delimiter)
            case $2 in
                tab|\t)
                    DELIMITER=$'\t'
                    ;;
                pipe|\|)
                    DELIMITER="|"
                    ;;
                comma|,)
                    DELIMITER=","
                    ;;
                *)
                    DELIMITER="$2"
                    ;;
            esac
            shift 2
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        -)
            INPUT="-"
            shift
            ;;
        *)
            if [[ -z "$INPUT" ]]; then
                INPUT="$1"
            fi
            shift
            ;;
    esac
done

# Validate action
if [[ -z "$ACTION" ]]; then
    echo -e "${COLOR_ERROR}Error: No action specified${COLOR_RESET}" >&2
    show_usage
    exit 1
fi

# Process
process_toon "$ACTION" "$INPUT" "$DELIMITER"
