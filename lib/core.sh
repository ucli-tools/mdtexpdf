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

# Note: truncate_address() is in lib/pdf.sh
# Note: filter path lookup is handled by find_lua_filter() in lib/pdf.sh

# =============================================================================
# Default Configuration
# =============================================================================

# Default TOC depth (3 = subsubsection level)
DEFAULT_TOC_DEPTH=2

# Default TOC setting (false = no TOC)
DEFAULT_TOC=false

# Default section numbering (true = numbered sections)
DEFAULT_SECTION_NUMBERS=true
