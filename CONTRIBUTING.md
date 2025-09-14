# Contributing to CheckRef

We welcome contributions from the genomics community! This document provides guidelines for contributing to the CheckRef pipeline.

## Code of Conduct

By participating in this project, you agree to abide by our [Code of Conduct](https://github.com/AfriGen-D/.github/blob/main/CODE_OF_CONDUCT.md).

## How to Contribute

### Reporting Issues

Before creating an issue, please:

1. **Search existing issues** to avoid duplicates
2. **Use the issue templates** provided
3. **Provide detailed information** including:
   - CheckRef version
   - Nextflow version
   - Operating system
   - Container system (Docker/Singularity)
   - Complete error messages
   - Minimal reproducible example

### Suggesting Enhancements

Enhancement suggestions are welcome! Please:

1. **Check existing feature requests** first
2. **Describe the enhancement** clearly
3. **Explain the use case** and benefits
4. **Consider implementation complexity**

### Contributing Code

#### Development Setup

```bash
# Fork and clone the repository
git clone https://github.com/YOUR_USERNAME/checkref.git
cd checkref

# Create a development branch
git checkout -b feature/your-feature-name

# Make your changes
# ...

# Test your changes
./test/test.sh

# Commit and push
git add .
git commit -m "feat: add your feature description"
git push origin feature/your-feature-name
```

#### Pull Request Process

1. **Create a feature branch** from `main`
2. **Make your changes** with clear, focused commits
3. **Add tests** for new functionality
4. **Update documentation** as needed
5. **Ensure all tests pass**
6. **Submit a pull request** with:
   - Clear description of changes
   - Reference to related issues
   - Screenshots/examples if applicable

#### Coding Standards

- **Follow existing code style** and conventions
- **Use meaningful variable names** and comments
- **Keep functions focused** and modular
- **Add docstrings** for new functions
- **Use conventional commit messages**:
  - `feat:` for new features
  - `fix:` for bug fixes
  - `docs:` for documentation changes
  - `test:` for test additions/changes
  - `refactor:` for code refactoring

### Testing

All contributions should include appropriate tests:

```bash
# Run the test suite
./test/test.sh

# Test with different profiles
nextflow run main.nf -profile test,docker
nextflow run main.nf -profile test,singularity
```

### Documentation

When contributing:

- **Update README.md** if adding new features
- **Add examples** for new functionality
- **Update parameter documentation**
- **Consider adding to the docs website**

## Development Guidelines

### Nextflow Best Practices

- Follow [Nextflow best practices](https://www.nextflow.io/docs/latest/getstarted.html)
- Use DSL2 syntax
- Implement proper error handling
- Add appropriate resource requirements
- Use containers for reproducibility

### Genomics Considerations

- **Validate input formats** thoroughly
- **Handle edge cases** in genomic data
- **Consider population diversity** in examples
- **Document computational requirements**
- **Address ethical considerations** for data use

## Getting Help

- **[Discussions](https://github.com/AfriGen-D/checkref/discussions)**: General questions and community support
- **[Issues](https://github.com/AfriGen-D/checkref/issues)**: Bug reports and feature requests
- **[Helpdesk](https://helpdesk.afrigen-d.org)**: Technical support
- **[AfriGen-D Community](https://github.com/orgs/AfriGen-D/discussions)**: Broader project discussions

## Recognition

Contributors will be acknowledged in:

- Repository contributors list
- Release notes for significant contributions
- Documentation credits
- Academic publications (for substantial contributions)

## License

By contributing to CheckRef, you agree that your contributions will be licensed under the [MIT License](LICENSE).

Thank you for contributing to CheckRef and advancing genomics research capabilities!
