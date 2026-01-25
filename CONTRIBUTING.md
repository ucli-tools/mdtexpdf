# Contributing to mdtexpdf

Thank you for your interest in contributing to mdtexpdf!

## Code of Conduct

Be respectful and constructive in all interactions.

## Getting Started

1. Fork the repository
2. Clone your fork: `git clone https://github.com/YOUR_USERNAME/mdtexpdf.git`
3. Create a branch: `git checkout -b feature/your-feature`
4. Make your changes
5. Run tests: `make test`
6. Submit a pull request

## Development Setup

### Prerequisites

- Bash 4.0+
- Pandoc 2.0+
- TexLive (full or basic + required packages)
- Docker (optional, for containerized testing)
- shellcheck (for linting)

### Running Tests

```bash
# Run all tests
make test

# Run shellcheck
make lint

# Build example documents
make examples
```

## Code Style Guide

### Shell Script Style

1. **Use `#!/bin/bash`** at the top of scripts
2. **Quote variables**: Always use `"$variable"` not `$variable`
3. **Use `local`** for function-scoped variables
4. **Separate declaration and assignment** for command substitution:
   ```bash
   # Good
   local result
   result=$(some_command)
   
   # Bad (masks return value)
   local result=$(some_command)
   ```

5. **Use `-r` with `read`** to prevent backslash mangling:
   ```bash
   read -r user_input
   ```

6. **Check exit codes directly**:
   ```bash
   # Good
   if command; then
       echo "success"
   fi
   
   # Bad
   command
   if [ $? -eq 0 ]; then
       echo "success"
   fi
   ```

7. **Use arrays for multiple options**:
   ```bash
   local -a options=()
   options+=("--flag1")
   options+=("--flag2")
   command "${options[@]}"
   ```

### Naming Conventions

- **Functions**: `snake_case` (e.g., `create_template_file`)
- **Local variables**: `snake_case` (e.g., `input_file`)
- **Global variables**: `UPPER_SNAKE_CASE` (e.g., `VERSION`, `DEBUG`)
- **Constants**: `UPPER_SNAKE_CASE` (e.g., `EXIT_SUCCESS`)

### Function Documentation

Add comments for non-trivial functions:

```bash
# Brief description of what the function does
# Arguments:
#   $1 - description of first argument
#   $2 - description of second argument (optional)
# Returns:
#   0 on success, non-zero on failure
# Outputs:
#   Writes result to stdout
function_name() {
    local arg1="$1"
    local arg2="${2:-default}"
    # ...
}
```

### Error Handling

Use consistent exit codes:

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | User error (invalid arguments, missing input) |
| 2 | Missing dependency |
| 3 | Conversion failure |
| 4 | File system error |
| 5 | Configuration error |

### Logging

Use the provided logging functions:

```bash
log_verbose "Informational message"  # Shows with --verbose
log_debug "Debug details"            # Shows with --debug
log_warn "Warning message"           # Always shows
log_error "Error message"            # Always shows to stderr
log_success "Success message"        # Always shows
```

## Pull Request Guidelines

1. **One feature per PR** - Keep changes focused
2. **Update tests** - Add tests for new features
3. **Update documentation** - Update README, help text, etc.
4. **Pass CI** - All tests and linting must pass
5. **Descriptive commits** - Use clear commit messages

### Commit Message Format

```
type: short description

Longer description if needed.

Fixes #123
```

Types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`

## Reporting Issues

When reporting bugs, include:

1. mdtexpdf version (`mdtexpdf --version`)
2. Operating system and version
3. Pandoc version (`pandoc --version`)
4. LaTeX distribution and version
5. Steps to reproduce
6. Expected vs actual behavior
7. Sample input file (if applicable)

## Feature Requests

Open an issue with:

1. Clear description of the feature
2. Use case / motivation
3. Proposed implementation (optional)

## Questions?

Open an issue with the "question" label.
