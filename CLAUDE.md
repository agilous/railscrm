# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Rails 8 CRM application modernized for the latest Rails ecosystem. The application manages contacts, accounts, leads, opportunities, tasks, and multi-association notes with a focus on clean, maintainable code and comprehensive test coverage.

## Development Commands

### Setup
```bash
./bin/setup                      # Initial setup: installs dependencies, prepares database, clears logs
bundle install                   # Install Ruby dependencies
npm install                      # Install JavaScript dependencies
```

### Running the Application
```bash
./bin/dev                        # Start Rails server with all watchers (recommended)
bundle exec rails server         # Start Rails server only
bin/rails server                 # Alternative Rails server command
```

### Testing
```bash
# Run all tests
bundle exec rspec                                  # Run all specs
bundle exec rspec --format documentation          # Detailed output
bundle exec rspec --format progress               # Progress bar output
bundle exec rspec --fail-fast                     # Stop on first failure

# Run specific tests
bundle exec rspec spec/models/contact_spec.rb     # Run specific file
bundle exec rspec spec/system/contacts_crud_spec.rb:460  # Run specific line

# System specs with browser
SHOW_BROWSER=1 bundle exec rspec spec/system/     # Show browser during system tests
HEADLESS=false bundle exec rspec spec/system/     # Run with visible browser
USE_SELENIUM=1 bundle exec rspec spec/system/     # Force Selenium driver

# JavaScript tests
npm test                                           # Run all JavaScript tests
npx jest                                          # Alternative Jest command
```

### Code Quality
```bash
# Ruby linting and security
bundle exec rubocop                               # Check Ruby style
bundle exec rubocop -a                            # Auto-fix style issues
bundle exec rubocop -A                            # Auto-fix all issues (aggressive)
bundle exec brakeman                              # Security analysis
bundle exec bundle-audit check                    # Check for security vulnerabilities

# JavaScript linting
npm run lint                                       # Check JavaScript style

# Full CI suite (ALWAYS RUN BEFORE COMMITTING)
./bin/ci                                          # Runs all tests, linting, and security checks
```

### Database Operations
```bash
bin/rails db:create                               # Create development and test databases
bin/rails db:migrate                              # Run pending migrations
bin/rails db:rollback                             # Rollback last migration
bin/rails db:reset                                # Drop, create, migrate, seed
bin/rails db:seed                                 # Load seed data
bin/rails db:prepare                              # Setup for development

# Test database
RAILS_ENV=test bin/rails db:migrate               # Migrate test database
RAILS_ENV=test bin/rails db:reset                 # Reset test database
```

### Rails Console
```bash
bin/rails console                                 # Development console
RAILS_ENV=test bin/rails console                  # Test console
```

### Asset Management
```bash
./bin/importmap pin [package]                     # Add JavaScript package via importmap
./bin/importmap unpin [package]                   # Remove JavaScript package
```

## Architecture

### Core Models
- **Contact**: Primary entity with full name, email, phone, and address
- **Account**: Organizations/companies
- **Lead**: Potential customers
- **Opportunity**: Sales opportunities with stages and amounts
- **Task**: Activities and to-dos
- **Note**: Multi-association notes that can belong to any model
- **User**: Authentication via Devise

### Key Features
- **Multi-association Notes**: Notes can be associated with any model type
- **Activity Scheduling**: Full calendar integration for tasks and activities
- **Modal Forms**: JavaScript-powered modal interfaces for CRUD operations
- **Hotwire Integration**: Turbo and Stimulus for modern interactivity
- **Comprehensive Search**: Search across contacts, accounts, and leads

### Directory Structure
```
app/
├── controllers/           # Rails controllers
├── models/               # ActiveRecord models
├── views/                # ERB templates
├── javascript/           # Stimulus controllers and JavaScript
│   ├── controllers/      # Stimulus controllers
│   └── application.js    # Main JavaScript entry
├── assets/               # CSS and images
└── helpers/              # View helpers

spec/
├── models/               # Model specs
├── system/               # System/feature specs with Capybara
├── requests/             # Request/controller specs
├── factories/            # FactoryBot factories
├── support/              # Test helpers and configuration
└── javascript/           # JavaScript unit tests

config/
├── routes.rb            # Application routing
├── database.yml         # Database configuration
└── importmap.rb         # JavaScript import configuration
```

### Testing Strategy

**Use TDD and lint as you go.** When developing new features or fixing bugs:

1. Write a failing spec(s) first (when appropriate)
2. Implement the code to make the spec(s) pass

- **System Specs**: Full user workflows using Capybara with Playwright
- **Model Specs**: Validations, associations, and business logic
- **Request Specs**: Controller behavior and API responses
- **JavaScript Tests**: Jest tests for Stimulus controllers
- **Factory Bot**: Test data generation
- **Transactional Fixtures**: Rails' built-in test isolation (no Database Cleaner needed)

### JavaScript Stack
- **Stimulus**: Modest JavaScript framework for HTML you already have
- **Turbo**: SPA-like experience without complexity
- **Importmap**: Modern JavaScript without build step
- **Tailwind CSS**: Utility-first CSS framework

## Common Development Patterns

When in doubt follow the Rails guides: https://guides.rubyonrails.org/

### Adding New Features
Being mindful that we use TDD as mentioned previously...
1. Create migrations for any database changes
2. Add model validations and associations
3. Create controller actions following RESTful conventions
4. Add views using existing patterns (modals, tables, forms)
5. Add Stimulus controllers for JavaScript behavior
6. **CRITICAL**: Always run `./bin/ci` and correct all issues before committing

### Working with Modals
- Modals are implemented using Stimulus controllers
- Forms submit via Turbo for seamless updates
- Use `data-action` and `data-target` attributes for behavior

### Multi-Association Notes Pattern
Notes can belong to any model using polymorphic associations:
```ruby
# In models
has_many :notes, as: :notable, dependent: :destroy

# In controllers
@notes = @contact.notes.includes(:user)
```

### Authentication
- Uses Devise for user authentication
- Protected routes use `before_action :authenticate_user!`
- User sessions and registration handled by Devise

## Development Best Practices

### Critical Rules
1. **ALWAYS run `./bin/ci` before committing** - All checks must pass
2. **Follow Rails conventions** - Convention over configuration
3. **Write tests first** - TDD/BDD approach for new features
4. **Use existing patterns** - Check similar code before implementing
5. **Keep controllers thin** - Business logic belongs in models/services

### Git Workflow
```bash
# Before committing
./bin/ci                                          # Must return 0 (all green)

# Creating commits
git add .
git commit -m "Descriptive message"

# Creating pull requests (when requested)
gh pr create --title "Title" --body "Description"
```

### Common Issues and Solutions

#### Chrome/ChromeDriver Issues
If system specs fail with Chrome errors:
```bash
# Check Chrome version
/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --version

# Update ChromeDriver if needed
brew upgrade chromedriver
```

#### Test Database Issues
```bash
RAILS_ENV=test bin/rails db:migrate
RAILS_ENV=test bin/rails db:reset
```

#### JavaScript Not Loading
- Check `config/importmap.rb` for pin mappings
- Verify Stimulus controllers are registered
- Check browser console for errors

## Project-Specific Configuration

### Environment Variables
- Standard Rails credentials for secrets
- Database configuration in `config/database.yml`
- Test environment uses separate test database

### CI/CD Pipeline
The `./bin/ci` script runs:
1. RSpec tests (models, system, requests)
2. JavaScript tests (Jest)
3. RuboCop (Ruby linting)
4. Brakeman (security analysis)
5. Bundle audit (dependency vulnerabilities)
6. NPM audit (JavaScript vulnerabilities)

**NEVER COMMIT CODE WHILE THE LOCAL BUILD IS NOT PASSING**

### Browser Testing Configuration
- Uses Playwright with headless browser by default
- `SHOW_BROWSER=1` to see browser during tests
- `HEADLESS=false` for debugging
- `USE_SELENIUM=1` to force Selenium driver (fallback option)

## Key Commands Summary

```bash
# Development
./bin/dev                        # Start development server
./bin/ci                         # Run full CI suite (ALWAYS before commit)

# Testing
bundle exec rspec                # Run all tests
npm test                         # Run JavaScript tests

# Code Quality
bundle exec rubocop -A           # Auto-fix Ruby style
npm run lint                     # Check JavaScript

# Database
bin/rails db:migrate            # Run migrations
bin/rails db:seed              # Load seed data
```

Remember: The codebase follows standard Rails conventions with a focus on clean, maintainable code and comprehensive test coverage. Always ensure `./bin/ci` passes before committing changes.