# Contributing to Wazuh Deployment

Thank you for your interest in contributing! This document provides guidelines for contributing to this Wazuh deployment project.

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check existing issues. When creating a bug report, include:

- **Description**: Clear description of the issue
- **Steps to Reproduce**: Detailed steps to reproduce the problem
- **Expected Behavior**: What you expected to happen
- **Actual Behavior**: What actually happened
- **Environment**:
  - OS and version
  - Docker version
  - Docker Compose version
  - Wazuh version
- **Logs**: Relevant log output
- **Screenshots**: If applicable

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an enhancement suggestion, include:

- **Use Case**: Why this enhancement would be useful
- **Description**: Clear description of the enhancement
- **Examples**: Examples of how it would work
- **Alternatives**: Alternative solutions you've considered

### Pull Requests

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Test your changes thoroughly
5. Commit with clear messages (`git commit -m 'Add amazing feature'`)
6. Push to your branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

#### Pull Request Guidelines

- Follow existing code style and conventions
- Update documentation for any changes
- Add tests if applicable
- Keep changes focused and atomic
- Reference related issues
- Include a clear description of changes

## Development Setup

### Prerequisites

- Docker (20.10+)
- Docker Compose (2.0+)
- Git
- Bash shell

### Testing Changes

Before submitting a PR:

1. **Test the installation**:
   ```bash
   ./wazuh.sh install
   ```

2. **Verify all commands work**:
   ```bash
   ./wazuh.sh status
   ./wazuh.sh logs
   ./wazuh.sh backup
   ```

3. **Check script syntax**:
   ```bash
   bash -n wazuh.sh
   shellcheck wazuh.sh
   ```

4. **Validate Docker Compose**:
   ```bash
   docker-compose config
   ```

5. **Test cleanup**:
   ```bash
   ./wazuh.sh uninstall
   ```

## Code Style

### Shell Scripts

- Use bash shebang: `#!/bin/bash`
- Set error handling: `set -e`
- Use functions for reusable code
- Add comments for complex logic
- Use meaningful variable names
- Quote variables: `"$variable"`
- Use lowercase for local variables
- Use UPPERCASE for constants

Example:
```bash
#!/bin/bash
set -e

CONSTANT_VALUE="value"
local_variable="value"

function my_function() {
    local param="$1"
    echo "Processing: $param"
}
```

### Docker Compose

- Use version 3.8+
- Include service descriptions
- Use named volumes
- Add health checks where applicable
- Document environment variables
- Use consistent indentation (2 spaces)

### Documentation

- Use Markdown format
- Include code examples
- Add table of contents for long documents
- Keep line length reasonable (~80-100 chars)
- Use proper heading hierarchy
- Include links to references

## Commit Messages

Follow conventional commit format:

```
type(scope): subject

body

footer
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting)
- `refactor`: Code refactoring
- `test`: Adding tests
- `chore`: Maintenance tasks

**Examples:**
```
feat(backup): add encrypted backup support

Implements encryption for backup files using OpenSSL

Closes #123
```

```
fix(install): handle missing config directory

Ensures config directory exists before generating certificates

Fixes #456
```

## Documentation Updates

When making changes, update relevant documentation:

- `README.md` - Main documentation
- `QUICKSTART.md` - Quick start guide
- `ADVANCED.md` - Advanced configurations
- `SECURITY.md` - Security considerations
- `CONTRIBUTING.md` - This file

## Testing

### Manual Testing

Test matrix:

| OS | Docker Version | Docker Compose Version | Status |
|----|----------------|------------------------|--------|
| Ubuntu 22.04 | 24.0+ | 2.20+ | ✅ |
| Ubuntu 20.04 | 20.10+ | 2.0+ | ✅ |
| Debian 11 | 20.10+ | 2.0+ | ✅ |
| CentOS 8 | 20.10+ | 2.0+ | ⚠️ |
| macOS | 24.0+ | 2.20+ | ✅ |

### Automated Testing

While we don't have automated tests yet, contributions to add them are welcome:

- Shell script tests (bats, shunit2)
- Docker Compose validation
- Integration tests
- CI/CD pipeline

## Security

- Never commit sensitive information
- Use environment variables for secrets
- Test security configurations
- Review security implications of changes
- Report security issues privately (see SECURITY.md)

## License

By contributing, you agree that your contributions will be licensed under the same license as the project.

## Questions?

- Open an issue for questions
- Check existing documentation
- Review closed issues for similar problems

## Recognition

Contributors will be recognized in the repository and release notes.

Thank you for contributing! 🎉
