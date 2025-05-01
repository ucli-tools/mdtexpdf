# Contributing to mdtexpdf

Thank you for considering contributing to mdtexpdf! This document provides guidelines and instructions for contributing to this project.

## Code of Conduct

By participating in this project, you agree to maintain a respectful and inclusive environment for everyone.

## How Can I Contribute?

### Reporting Bugs

If you find a bug, please create an issue on GitHub with the following information:
- A clear, descriptive title
- Steps to reproduce the issue
- Expected behavior
- Actual behavior
- Any relevant logs or screenshots
- Your operating system and version
- Versions of relevant software (Pandoc, LaTeX, etc.)

### Suggesting Enhancements

If you have ideas for new features or improvements, please create an issue on GitHub with:
- A clear, descriptive title
- A detailed description of the proposed enhancement
- Any relevant examples, mockups, or use cases

### Pull Requests

1. Fork the repository
2. Create a new branch (`git checkout -b feature/your-feature-name`)
3. Make your changes
4. Run tests if available
5. Commit your changes (`git commit -m 'Add some feature'`)
6. Push to the branch (`git push origin feature/your-feature-name`)
7. Create a new Pull Request

## Development Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/mik-tf/mdtexpdf.git
   cd mdtexpdf
   ```

2. Make the script executable:
   ```bash
   chmod +x mdtexpdf.sh
   ```

3. Install dependencies:
   - Pandoc: https://pandoc.org/installing.html
   - LaTeX: A distribution like TexLive, MacTeX, or MiKTeX

## Coding Style

- Use 4 spaces for indentation in Bash scripts
- Add comments for complex logic
- Follow the existing code style

## Testing

Before submitting a pull request, please test your changes:
- Test the script with various Markdown files
- Verify that the generated PDFs look correct
- Check that all commands work as expected

## Documentation

If you add new features or make significant changes, please update the documentation:
- Update the README.md file
- Update the help function in the script
- Add examples if appropriate

## License

By contributing to this project, you agree that your contributions will be licensed under the project's [Apache 2.0 License](LICENSE).