#!/bin/bash
# =============================================================================
# mdtexpdf Simple Bibliography Module
# Converts Markdown bibliography format to CSL-JSON for Pandoc
# =============================================================================

# Source core module if not already loaded
if [ -z "$MDTEXPDF_VERSION" ]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "$SCRIPT_DIR/core.sh"
fi

# Global variable to track used keys (reset per conversion)
_USED_KEYS=""

# =============================================================================
# Citation Key Generation
# =============================================================================

# Generate citation key from author and year
# Usage: generate_citation_key "Knuth, Donald E." "1968"
# Output: knuth1968
generate_citation_key() {
    local author="$1"
    local year="$2"

    # Extract first author's surname (before the comma)
    local surname
    surname=$(echo "$author" | sed 's/,.*//' | sed 's/ and .*//')

    # Convert to lowercase, remove spaces and special characters
    local key
    key=$(echo "$surname" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]//g')

    # Append year
    echo "${key}${year}"
}

# Handle duplicate keys by appending a, b, c, etc.
# Usage: get_unique_key "einstein1905"
# Output: einstein1905 or einstein1905b, etc.
# Uses global _USED_KEYS variable
get_unique_key() {
    local base_key="$1"

    # Check if base key exists
    local key="$base_key"
    local count=0

    while [[ " ${_USED_KEYS} " =~ " ${key} " ]]; do
        count=$((count + 1))
        # a=1, b=2, c=3, etc.
        local suffix
        suffix=$(printf "\\x$(printf '%02x' $((96 + count)))")
        key="${base_key}${suffix}"
    done

    # Add to used keys
    _USED_KEYS="${_USED_KEYS} ${key}"

    echo "$key"
}

# =============================================================================
# Markdown Bibliography Parser
# =============================================================================

# Parse a single bibliography entry from a temp file
# Usage: parse_bib_entry_from_file /path/to/temp/entry
# Returns JSON object for CSL-JSON
parse_bib_entry_from_file() {
    local entry_file="$1"

    local key=""
    local author=""
    local title=""
    local year=""
    local entry_type="misc"
    local journal=""
    local publisher=""
    local volume=""
    local number=""
    local pages=""
    local doi=""
    local url=""
    local note=""

    # Parse each field from file
    while IFS= read -r line; do
        # Remove leading dash, spaces, and indentation
        line=$(echo "$line" | sed 's/^-[[:space:]]*//' | sed 's/^[[:space:]]*//')

        # Extract field name and value (Field: Value)
        if [[ "$line" =~ ^([A-Za-z]+):[[:space:]]*(.*)$ ]]; then
            local field="${BASH_REMATCH[1]}"
            local value="${BASH_REMATCH[2]}"

            # Trim whitespace from value
            value=$(echo "$value" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

            case "${field,,}" in  # lowercase comparison
                key) key="$value" ;;
                author) author="$value" ;;
                title) title="$value" ;;
                year) year="$value" ;;
                type) entry_type="$value" ;;
                journal) journal="$value" ;;
                publisher) publisher="$value" ;;
                volume) volume="$value" ;;
                number|issue) number="$value" ;;
                pages) pages="$value" ;;
                doi) doi="$value" ;;
                url) url="$value" ;;
                note) note="$value" ;;
            esac
        fi
    done < "$entry_file"

    # Validate required fields
    if [ -z "$author" ] || [ -z "$title" ] || [ -z "$year" ]; then
        log_warn "Bibliography entry missing required fields (Author, Title, Year)"
        return 1
    fi

    # Generate key if not provided
    if [ -z "$key" ]; then
        local base_key
        base_key=$(generate_citation_key "$author" "$year")
        key=$(get_unique_key "$base_key")
    else
        # Even custom keys need to be tracked
        _USED_KEYS="${_USED_KEYS} ${key}"
    fi

    log_debug "Parsed entry: $key ($author, $year)"

    # Map entry type to CSL type
    local csl_type
    case "${entry_type,,}" in
        book) csl_type="book" ;;
        article) csl_type="article-journal" ;;
        report) csl_type="report" ;;
        patent) csl_type="patent" ;;
        web) csl_type="webpage" ;;
        *) csl_type="document" ;;
    esac

    # Build CSL-JSON object
    local json="{"
    json+="\"id\":\"$key\","
    json+="\"type\":\"$csl_type\","

    # Parse authors into CSL format
    json+="\"author\":["
    local first_author=true

    # Split authors by " and " - replace with newline and process
    local author_list
    author_list=$(echo "$author" | sed 's/ and /\n/g')

    while IFS= read -r auth; do
        # Skip empty entries
        [ -z "$auth" ] && continue

        if [ "$first_author" = false ]; then
            json+=","
        fi
        first_author=false

        # Trim whitespace
        auth=$(echo "$auth" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

        # Parse "Surname, Given" or just "Name"
        if [[ "$auth" =~ ^([^,]+),\ *(.*)$ ]]; then
            local family="${BASH_REMATCH[1]}"
            local given="${BASH_REMATCH[2]}"
            # Escape quotes in names
            family=$(echo "$family" | sed 's/"/\\"/g')
            given=$(echo "$given" | sed 's/"/\\"/g')
            json+="{\"family\":\"$family\",\"given\":\"$given\"}"
        else
            # Institutional author or single name
            auth=$(echo "$auth" | sed 's/"/\\"/g')
            json+="{\"literal\":\"$auth\"}"
        fi
    done <<< "$author_list"
    json+="],"

    # Escape and add title
    local escaped_title
    escaped_title=$(echo "$title" | sed 's/"/\\"/g')
    json+="\"title\":\"$escaped_title\","

    # Add date
    json+="\"issued\":{\"date-parts\":[[$year]]}"

    # Optional fields
    if [ -n "$journal" ]; then
        local escaped_journal
        escaped_journal=$(echo "$journal" | sed 's/"/\\"/g')
        json+=",\"container-title\":\"$escaped_journal\""
    fi

    if [ -n "$publisher" ]; then
        local escaped_publisher
        escaped_publisher=$(echo "$publisher" | sed 's/"/\\"/g')
        json+=",\"publisher\":\"$escaped_publisher\""
    fi

    if [ -n "$volume" ]; then
        json+=",\"volume\":\"$volume\""
    fi

    if [ -n "$number" ]; then
        json+=",\"issue\":\"$number\""
    fi

    if [ -n "$pages" ]; then
        # Convert -- to - for CSL
        pages=$(echo "$pages" | sed 's/--/-/g')
        json+=",\"page\":\"$pages\""
    fi

    if [ -n "$doi" ]; then
        json+=",\"DOI\":\"$doi\""
    fi

    if [ -n "$url" ]; then
        local escaped_url
        escaped_url=$(echo "$url" | sed 's/"/\\"/g')
        json+=",\"URL\":\"$escaped_url\""
    fi

    if [ -n "$note" ]; then
        local escaped_note
        escaped_note=$(echo "$note" | sed 's/"/\\"/g')
        json+=",\"note\":\"$escaped_note\""
    fi

    json+="}"

    echo "$json"
}

# =============================================================================
# Main Conversion Function
# =============================================================================

# Convert markdown bibliography to CSL-JSON
# Usage: convert_simple_bibliography input.md output.json
# Returns: 0 on success, 1 on failure
convert_simple_bibliography() {
    local input_file="$1"
    local output_file="$2"

    if [ ! -f "$input_file" ]; then
        log_error "Bibliography file not found: $input_file"
        return 1
    fi

    log_verbose "Converting simple bibliography: $input_file"

    # Reset used keys tracker
    _USED_KEYS=""

    # Create temp directory for entry files
    local temp_dir
    temp_dir=$(mktemp -d)
    trap "rm -rf $temp_dir" EXIT

    # Collect all JSON entries
    local -a json_entries=()

    # Parse the file
    local entry_file="$temp_dir/entry.txt"
    local in_entry=false
    local entry_count=0

    while IFS= read -r line || [ -n "$line" ]; do
        # Skip empty lines and headings
        if [[ -z "$line" ]] || [[ "$line" =~ ^#+ ]]; then
            # If we were in an entry, process it
            if [ "$in_entry" = true ] && [ -f "$entry_file" ]; then
                local json
                json=$(parse_bib_entry_from_file "$entry_file")
                if [ -n "$json" ]; then
                    json_entries+=("$json")
                fi
                rm -f "$entry_file"
                in_entry=false
            fi
            continue
        fi

        # Check if this is the start of a new entry (line starts with -)
        if [[ "$line" =~ ^-[[:space:]]+ ]]; then
            # Process previous entry if exists
            if [ "$in_entry" = true ] && [ -f "$entry_file" ]; then
                local json
                json=$(parse_bib_entry_from_file "$entry_file")
                if [ -n "$json" ]; then
                    json_entries+=("$json")
                fi
                rm -f "$entry_file"
            fi
            in_entry=true
            entry_count=$((entry_count + 1))
            echo "$line" > "$entry_file"
        elif [ "$in_entry" = true ]; then
            # Continuation of current entry (indented line)
            echo "$line" >> "$entry_file"
        fi
    done < "$input_file"

    # Process last entry
    if [ "$in_entry" = true ] && [ -f "$entry_file" ]; then
        local json
        json=$(parse_bib_entry_from_file "$entry_file")
        if [ -n "$json" ]; then
            json_entries+=("$json")
        fi
    fi

    # Build final JSON array
    local output="["
    local first=true
    for entry in "${json_entries[@]}"; do
        if [ "$first" = false ]; then
            output+=","
        fi
        first=false
        output+="$entry"
    done
    output+="]"

    # Write output
    echo "$output" > "$output_file"

    log_verbose "Generated CSL-JSON with ${#json_entries[@]} entries"
    log_debug "Used citation keys:$_USED_KEYS"

    return 0
}

# =============================================================================
# Detection Function
# =============================================================================

# Check if a file is a simple markdown bibliography
# Usage: is_simple_bibliography file.md
# Returns: 0 if yes, 1 if no
is_simple_bibliography() {
    local file="$1"

    # Check extension
    if [[ "$file" != *.md ]]; then
        return 1
    fi

    # Check if file contains bibliography-style entries
    # Look for pattern: "- Author:" or "- Key:"
    if grep -qE '^-[[:space:]]+(Author|Key):' "$file" 2>/dev/null; then
        return 0
    fi

    return 1
}

# =============================================================================
# Integration Helper
# =============================================================================

# Process bibliography file, converting if needed
# Usage: process_bibliography_file input_file temp_dir
# Output: Path to bibliography file (original .bib or converted .json)
process_bibliography_file() {
    local input_file="$1"
    local temp_dir="$2"

    if is_simple_bibliography "$input_file"; then
        local output_file="$temp_dir/bibliography.json"
        if convert_simple_bibliography "$input_file" "$output_file"; then
            echo "$output_file"
            return 0
        else
            return 1
        fi
    else
        # Return original file (assume it's .bib or already CSL-JSON)
        echo "$input_file"
        return 0
    fi
}
