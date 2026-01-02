# Contributing to AsyncFlow

First off, thank you for considering contributing to AsyncFlow! 🎉

AsyncFlow is an open source project and we love to receive contributions from our community. There are many ways to contribute, from writing tutorials or blog posts, improving the documentation, submitting bug reports and feature requests or writing code.

## Code of Conduct

This project and everyone participating in it is governed by our Code of Conduct. By participating, you are expected to uphold this code.

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check the existing issues as you might find out that you don't need to create one. When you are creating a bug report, please include as many details as possible.

#### How Do I Submit A Bug Report?

Bugs are tracked as GitHub issues. Create an issue and provide the following information:

- **Use a clear and descriptive title** for the issue
- **Describe the exact steps which reproduce the problem**
- **Provide specific examples to demonstrate the steps**
- **Describe the behavior you observed after following the steps**
- **Explain which behavior you expected to see instead and why**
- **Include screenshots or animated GIFs** if possible
- **Include your environment details** (OS version, Swift version, Xcode version)

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an enhancement suggestion, please include:

- **Use a clear and descriptive title**
- **Provide a step-by-step description of the suggested enhancement**
- **Provide specific examples to demonstrate the steps**
- **Describe the current behavior** and **explain which behavior you expected to see instead**
- **Explain why this enhancement would be useful**

### Pull Requests

#### Before Submitting a Pull Request

1. Fork the repository
2. Create a new branch from `main`
3. Make your changes
4. Add tests if applicable
5. Ensure all tests pass
6. Update documentation as needed
7. Follow the coding style guidelines

#### Pull Request Process

1. Update the README.md with details of changes if needed
2. Update the documentation with any new features
3. The PR will be merged once you have the sign-off of the maintainers

#### Coding Style Guidelines

- Follow Swift API Design Guidelines
- Use meaningful variable and function names
- Add comments for complex logic
- Keep functions small and focused
- Write unit tests for new functionality
- Ensure all tests pass before submitting

#### Commit Message Guidelines

We follow the Conventional Commits specification:

```
<type>(<scope>): <subject>

<body>

<footer>
```

Types:
- `feat`: A new feature
- `fix`: A bug fix
- `docs`: Documentation only changes
- `style`: Code style changes (formatting, semicolons, etc)
- `refactor`: Code change that neither fixes a bug nor adds a feature
- `perf`: Performance improvements
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

Example:
```
feat(coordinator): add deep link support

Added ability to navigate to specific screens via deep links.
This allows external apps to open specific content.

Closes #123
```

### Testing

- Write tests for all new features
- Ensure existing tests pass
- Run tests with `tuist test AsyncFlow`
- Add integration tests when appropriate

### Documentation

- Update API documentation using DocC
- Add code examples for new features
- Update README.md if needed
- Keep documentation in sync with code

## Development Setup

1. Install Tuist:
```bash
curl -Ls https://install.tuist.io | bash
```

2. Clone the repository:
```bash
git clone https://github.com/Jimmy-Jung/AsyncFlow.git
cd AsyncFlow
```

3. Generate Xcode project:
```bash
tuist install
tuist generate
```

4. Open in Xcode:
```bash
open AsyncFlow.xcworkspace
```

## Project Structure

```
AsyncFlow/
├── Projects/
│   ├── AsyncFlow/              # Core library
│   │   ├── Sources/
│   │   │   ├── Core/          # Core types
│   │   │   ├── Integration/   # Platform integration
│   │   │   ├── Testing/       # Testing utilities
│   │   │   └── Utilities/     # Helper types
│   │   └── Tests/             # Unit tests
│   └── AsyncFlowExample/       # Example app
└── Tuist/                      # Tuist configuration
```

## Testing Your Changes

### Unit Tests

```bash
tuist test AsyncFlow
```

### Example App

```bash
tuist run AsyncFlowExample
```

### Manual Testing

1. Test on different iOS versions (iOS 15+)
2. Test on different devices (iPhone, iPad)
3. Test edge cases
4. Test memory management

## Questions?

Feel free to reach out:
- Open an issue with the `question` label
- Start a discussion in GitHub Discussions

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

Thank you for contributing to AsyncFlow! 🚀

