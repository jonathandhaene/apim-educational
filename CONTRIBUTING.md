# Contributing to Azure APIM Educational Repository

Thank you for your interest in contributing! This document provides guidelines and workflows for contributing to this educational repository.

## 🎯 Types of Contributions

We welcome:
- **Documentation improvements**: Fixing typos, clarifying concepts, adding examples
- **New labs**: Additional hands-on exercises and tutorials
- **Infrastructure templates**: Improvements to Bicep/Terraform modules
- **Policy examples**: New or improved APIM policy recipes
- **Test cases**: Additional Postman/REST Client/k6 tests
- **Bug fixes**: Corrections to code, scripts, or workflows
- **Feature additions**: New capabilities aligned with educational goals

## 🔄 Contribution Workflow

### 1. Fork and Clone

```bash
# Fork the repository on GitHub, then clone your fork
git clone https://github.com/YOUR-USERNAME/apim-educational.git
cd apim-educational

# Add upstream remote
git remote add upstream https://github.com/jonathandhaene/apim-educational.git
```

### 2. Create a Branch

```bash
# Create a descriptive branch name
git checkout -b feature/add-cosmos-backend-example
# or
git checkout -b fix/bicep-parameter-typo
# or
git checkout -b docs/improve-networking-guide
```

### 3. Make Your Changes

Follow the guidelines below for your specific contribution type.

### 4. Test Your Changes

**For Infrastructure Code:**
```bash
# Bicep: Validate templates
az bicep build --file infra/bicep/main.bicep

# Terraform: Validate configuration
cd infra/terraform
terraform init
terraform validate
terraform fmt -check
```

**For Documentation:**
- Check for broken links
- Verify markdown formatting
- Ensure code blocks are properly formatted
- Test any commands or scripts you document

**For Policies:**
- Validate XML syntax
- Test policy behavior if possible
- Include clear comments explaining policy logic

**For Scripts:**
```bash
# PowerShell: Use PSScriptAnalyzer
Invoke-ScriptAnalyzer -Path scripts/*.ps1

# Bash: Use shellcheck
shellcheck scripts/*.sh
```

### 5. Lint Your Changes

```bash
# Markdown linting (if markdownlint is configured)
markdownlint '**/*.md' --ignore node_modules

# YAML linting for workflows
yamllint .github/workflows/
```

### 6. Commit Your Changes

Write clear, descriptive commit messages:

```bash
git add .
git commit -m "Add Cosmos DB backend policy example"
```

**Commit Message Guidelines:**
- Use present tense ("Add feature" not "Added feature")
- Be specific and descriptive
- Reference issues when applicable: "Fix #123: Correct parameter name"
- Keep first line under 72 characters
- Add detailed explanation in body if needed

### 7. Push and Create Pull Request

```bash
# Push to your fork
git push origin feature/add-cosmos-backend-example
```

Then create a Pull Request on GitHub with:
- **Clear title**: Summarize the change
- **Description**: Explain what, why, and how
- **Related issues**: Link any related issues
- **Testing**: Describe how you tested
- **Screenshots**: Include for UI or documentation changes

## 📋 Contribution Guidelines by Type

### Documentation

- **Clarity**: Write for beginners; explain concepts clearly
- **Examples**: Include practical, working examples
- **Structure**: Use consistent headings and formatting
- **Links**: Prefer Microsoft Learn official documentation
- **Code blocks**: Always specify language for syntax highlighting

Example:
````markdown
### Deploying with Bicep

```bash
az deployment group create \
  --resource-group rg-apim \
  --template-file main.bicep \
  --parameters env=dev
```
````

### Infrastructure Code

**Bicep:**
- Use parameters for configurable values
- Include descriptions for all parameters
- Output important values (resource IDs, endpoints)
- Use modules for reusability
- Follow Azure naming conventions
- Add inline comments for complex logic

**Terraform:**
- Use variables with descriptions and types
- Validate with `terraform fmt` and `terraform validate`
- Include outputs for important values
- Use modules for reusability
- Add comments for complex expressions
- Pin provider versions

### Policy Examples

- **File naming**: Use descriptive names (e.g., `jwt-validate-entra-id.xml`)
- **Comments**: Explain each policy section
- **Placeholders**: Use `{{named-value}}` syntax for secrets
- **Documentation**: Add README.md explaining when/how to use
- **Testing**: Describe how to test the policy

### Labs

- **Structure**: Include README.md with clear steps
- **Prerequisites**: List required tools and access
- **Duration**: Estimate time to complete
- **Learning objectives**: State what learners will accomplish
- **Validation**: Include steps to verify completion
- **Cleanup**: Provide resource cleanup instructions

### Scripts

- **Cross-platform**: Provide both .ps1 and .sh versions when possible
- **Parameters**: Accept inputs via command-line arguments
- **Error handling**: Check prerequisites and handle failures
- **Help text**: Include usage instructions
- **Idempotency**: Safe to run multiple times
- **Logging**: Output progress and results

## ✅ Code Quality Standards

### General Standards
- No hardcoded secrets or credentials
- Use placeholders with TODO comments for environment-specific values
- Include error handling in scripts
- Follow existing code style and patterns
- Add comments for complex logic

### Markdown
- Use ATX-style headers (`#` not underlines)
- One sentence per line for easier diffs
- Use fenced code blocks with language specified
- Check spelling and grammar

### YAML (GitHub Actions)
- Use 2 spaces for indentation
- Quote string values containing special characters
- Use meaningful job and step names
- Add comments for complex workflows

## 🧪 Testing Expectations

### Before Submitting PR

1. **Local validation**: Run applicable linters and validators
2. **Functionality**: Test scripts, templates, and commands work
3. **Documentation**: Verify instructions are accurate
4. **CI checks**: Ensure GitHub Actions workflows will pass

### CI Checks That Must Pass

- **Bicep build**: All .bicep files must compile
- **Terraform validate**: All .tf files must validate
- **Markdown lint**: Documentation must follow standards
- **YAML lint**: Workflow files must be valid
- **Link check**: No broken links in documentation
- **Spectral**: OpenAPI definitions must be valid

## 🔍 Code Review Process

1. **Automated checks**: CI must pass before review
2. **Maintainer review**: At least one maintainer approval required
3. **Feedback**: Address review comments promptly
4. **Updates**: Push additional commits to same branch
5. **Merge**: Maintainer will merge when ready

## 💬 Getting Help

- **Questions**: Open a GitHub Discussion
- **Bugs**: Create an issue with reproduction steps
- **Feature ideas**: Open an issue for discussion first
- **Urgent issues**: Tag with appropriate priority label

## 📜 Code of Conduct

### Our Standards

- **Be respectful**: Treat everyone with respect and kindness
- **Be constructive**: Provide helpful, actionable feedback
- **Be collaborative**: Work together toward better solutions
- **Be patient**: Remember we're all learning

### Unacceptable Behavior

- Harassment, discrimination, or offensive comments
- Trolling or insulting remarks
- Publishing others' private information
- Unprofessional conduct

## 🏷️ Issue and PR Labels

- `documentation`: Documentation improvements
- `enhancement`: New features or improvements
- `bug`: Bug fixes
- `lab`: New or improved labs
- `infrastructure`: Bicep/Terraform changes
- `policy`: APIM policy examples
- `help-wanted`: Good for new contributors
- `good-first-issue`: Ideal for first-time contributors

## 📝 License

By contributing, you agree that your contributions will be licensed under the same license as the project (see LICENSE file).

## 🙏 Recognition

Contributors will be recognized in release notes and the repository README. Thank you for making this educational resource better!

---

**Questions?** Feel free to open an issue or start a discussion. We're here to help!
