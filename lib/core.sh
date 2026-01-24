#!/bin/bash
# =============================================================================
# mdtexpdf Core Module
# Common utilities, logging, and configuration
# =============================================================================

# Version (should match main script)
MDTEXPDF_VERSION="${MDTEXPDF_VERSION:-1.0.0}"

# Verbosity levels (can be set before sourcing)
VERBOSE="${VERBOSE:-false}"
DEBUG="${DEBUG:-false}"

# ANSI color codes
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# =============================================================================
# Logging Functions
# =============================================================================

log_verbose() {
    if [ "$VERBOSE" = true ] || [ "$DEBUG" = true ]; then
        echo -e "${BLUE}[INFO]${NC} $*"
    fi
}

log_debug() {
    if [ "$DEBUG" = true ]; then
        echo -e "${PURPLE}[DEBUG]${NC} $*"
    fi
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*"
}

log_success() {
    echo -e "${GREEN}[OK]${NC} $*"
}

# =============================================================================
# Utility Functions
# =============================================================================

# Check if a command exists
check_command() {
    if ! command -v "$1" &> /dev/null; then
        echo -e "${RED}✗ $1 is not installed${NC}"
        return 1
    else
        echo -e "${GREEN}✓ $1 is installed${NC}"
        return 0
    fi
}

# Check if a LaTeX package is available
check_latex_package() {
    if kpsewhich "$1.sty" &> /dev/null; then
        echo -e "${GREEN}✓ LaTeX package $1 is available${NC}"
        return 0
    else
        echo -e "${RED}✗ LaTeX package $1 is not available${NC}"
        return 1
    fi
}

# Truncate long addresses/keys for display
truncate_address() {
    local address="$1"
    local max_length="${2:-40}"

    if [ ${#address} -gt $max_length ]; then
        local half=$(( (max_length - 3) / 2 ))
        echo "${address:0:$half}...${address: -$half}"
    else
        echo "$address"
    fi
}

# Get the directory where mdtexpdf is installed
get_mdtexpdf_dir() {
    local script_path
    script_path="$(readlink -f "${BASH_SOURCE[0]}")"
    dirname "$(dirname "$script_path")"
}

# Get path to a filter
get_filter_path() {
    local filter_name="$1"
    local mdtexpdf_dir
    mdtexpdf_dir="$(get_mdtexpdf_dir)"

    # Check multiple locations
    for path in \
        "$mdtexpdf_dir/filters/$filter_name" \
        "/usr/local/share/mdtexpdf/filters/$filter_name" \
        "./filters/$filter_name"; do
        if [ -f "$path" ]; then
            echo "$path"
            return 0
        fi
    done

    return 1
}

# =============================================================================
# Default Configuration
# =============================================================================

# Default TOC depth (3 = subsubsection level)
DEFAULT_TOC_DEPTH=2

# Default TOC setting (false = no TOC)
DEFAULT_TOC=false

# Default section numbering (true = numbered sections)
DEFAULT_SECTION_NUMBERS=true
