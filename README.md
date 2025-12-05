# Wendell CRM

This is a **Rails 8 modernization** of the original [Rails CRM](https://github.com/brobertsaz/railscrm) opensource Customer Relations Management application. While the original project was built with Rails 3.2.11 and MongoDB, this version has been completely rewritten for Rails 8 with modern best practices and updated technologies.

## What's New in This Version

This modernized version includes significant upgrades:

- **Rails 8.0** with Ruby 3.2.1
- **PostgreSQL** database (replacing MongoDB/Mongoid)
- **Tailwind CSS** for modern, responsive UI (replacing Twitter Bootstrap)
- **ERB templates** (replacing HAML)
- **Multi-association Notes System** - Attach notes to any entity (Leads, Contacts, Opportunities, etc.)
- **Comprehensive Test Suite** - RSpec, Capybara, and system tests
- **Modern JavaScript** - Stimulus controllers and Turbo
- **CI/CD Pipeline** - GitHub Actions for automated testing
- **Enhanced CRUD Operations** - Modern styling and improved user experience

## Technology Stack

- **Ruby** 3.2.1
- **Rails** 8.0
- **Node.js** 24.7.0
- **Database** PostgreSQL
- **Authentication** Devise
- **Styling** Tailwind CSS
- **JavaScript** Stimulus, Turbo
- **Testing** RSpec, Capybara, Playwright, Selenium WebDriver
- **Pagination** Kaminari

## Prerequisites

Before installing Wendell CRM, ensure you have the following installed:

### PostgreSQL

Wendell CRM uses PostgreSQL for its database. To install PostgreSQL:

**macOS (using Homebrew):**
```bash
brew install postgresql@14
brew services start postgresql@14
```

**Ubuntu/Debian:**
```bash
sudo apt-get update
sudo apt-get install postgresql postgresql-contrib libpq-dev
sudo service postgresql start
```

**Windows:**
Download and install from https://www.postgresql.org/download/windows/

### asdf (Version Manager)

This project uses [asdf](https://asdf-vm.com/) to manage Ruby, Node.js, and Python versions. The required versions are specified in `.tool-versions`:

- Ruby 3.2.1
- Node.js 24.7.0
- Python 3.12.0

**Install asdf:**
```bash
# See https://asdf-vm.com/guide/getting-started.html for detailed instructions
git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.14.0
```

**Install required plugins and versions:**
```bash
asdf plugin add ruby
asdf plugin add nodejs
asdf plugin add python
asdf install  # Installs all versions from .tool-versions
```

## Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/launchscout/wendellcrm.git
   cd wendellcrm
   ```

2. **Run the setup script**
   ```bash
   ./bin/setup
   ```

   This script will:
   - Install Ruby gem dependencies
   - Install Node.js dependencies
   - Install Playwright and its dependencies for testing
   - Set up the database
   - Clear logs and temporary files
   - Start the development server

   **Note:** To run setup without starting the server, use `./bin/setup --skip-server`

3. **Visit the application**

   Go to `http://localhost:3000` and create your first user account.

## Approval Process

By default, all users are automatically approved upon registration. To require admin approval for new users, edit `app/models/user.rb`:

```ruby
# Change line with :approved field default from true to false
field :approved, type: Boolean, default: false
```

## Work Flow

The intended CRM workflow:

1. **Create a Lead** - Potential customers enter the system as leads
2. **Create a Task for a Lead** - Assign follow-up tasks
3. **Convert Lead**
   - After qualifying a lead, it can be converted to a Contact
   - During conversion, an Opportunity can be created
4. **Create a Contact** - Contacts can also be created directly (not just from converted leads)
5. **Create an Account** - An account represents a company and can have many contacts

The initial setup requires creating Users who can be assigned leads, contacts, opportunities, and accounts.

## Web-to-Lead

Wendell CRM includes a web-to-lead function that generates embeddable forms for your website. When visitors submit these forms, new leads are automatically created in the CRM.

To use Web-to-Lead:

1. Go to **Leads** in the navigation
2. Click on **Web-to-Lead**
3. Configure your form:
   - Set a redirect URL (typically a "Thank You" page)
   - Select the fields you want to include
   - Click "Generate Form"
4. Copy the generated HTML code and paste it on your website

## Migrating from Pipedrive (Optional)

If you're currently using Pipedrive and want to pilot Wendell CRM, a one-way import tool is available to help you migrate your data. This allows you to evaluate Wendell CRM with your existing data before deciding whether to make the switch.

```bash
# Import all data from Pipedrive
rails pipedrive:sync
```

**Note:** This is a one-way import designed for migration and evaluation purposes, not ongoing synchronization. See [PIPEDRIVE_SYNC.md](PIPEDRIVE_SYNC.md) for setup instructions.

## Testing

Run the comprehensive test suite:

```bash
# Run all tests, linters, and security checks
./bin/ci
```

This script runs:
- RSpec tests (Ruby)
- JavaScript tests
- Rubocop linter (Ruby)
- JavaScript linter
- Brakeman security scanner

For running specific tests during development:

```bash
# Run specific test file
bundle exec rspec spec/models/lead_spec.rb

# Run system tests only
bundle exec rspec spec/system

# Run all RSpec tests only
bundle exec rspec
```

## Development

```bash
# Start development server (runs Rails server + Tailwind CSS watcher)
bin/dev

# Open Rails console
rails console

# Run database migrations
rails db:migrate

# Reset database (caution: destroys all data)
rails db:drop db:create db:migrate

# Build Tailwind CSS (for production)
rails tailwindcss:build
```

## Key Features

- **User Management** - Admin approval workflow, role-based access
- **Lead Management** - Track and convert leads to contacts/opportunities
- **Contact Management** - Maintain customer contact information
- **Account Management** - Organize contacts by company/organization
- **Opportunity Tracking** - Sales pipeline management
- **Task Management** - Assign and track to-dos
- **Notes System** - Attach notes to any entity (polymorphic associations)
- **Web-to-Lead Forms** - Generate embeddable lead capture forms
- **Modern UI** - Responsive design with Tailwind CSS
- **Comprehensive Testing** - Full test coverage with RSpec

## Development Roadmap

Wendell CRM has a comprehensive development roadmap that outlines planned features and implementation priorities. See [ROADMAP.md](ROADMAP.md) for:

- **Immediate Priorities** - Schedule Activity functionality and Web-to-Lead form completion
- **Implementation Phases** - Detailed sprint planning and effort estimates
- **Technical Considerations** - Performance, security, and data management strategies
- **Future Enhancements** - Email integration, reporting, and mobile improvements

The roadmap prioritizes building a complete standalone CRM solution with optional one-way migration support from Pipedrive.

## Project Structure

Key directories and files:

- `app/models/` - ActiveRecord models (User, Lead, Contact, Account, Opportunity, Task, Note)
- `app/controllers/` - Request handling and business logic
- `app/views/` - ERB templates
- `app/javascript/` - Stimulus controllers
- `spec/` - RSpec test suite
- `lib/pipedrive_sync.rb` - Optional Pipedrive import utility
- `db/schema.rb` - Database schema

## Original Project

This is a modernized fork of the original Rails CRM created by Bob Roberts. The original project can be found at:
https://github.com/brobertsaz/railscrm

The original was intentionally kept as a bare-bones solution. This modernization maintains that philosophy while updating to current Rails best practices.

## Contributing

Improvements and contributions are welcome! To contribute:

1. Fork the project
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

Please ensure:
- All tests pass (`bundle exec rspec`)
- Code follows Rails conventions
- New features include appropriate tests

## License

This project is based on the original Rails CRM by Bob Roberts and has been substantially rewritten and modernized.

**Original Work:**
Copyright © 2012 Bob Roberts <bob@rebel-outpost.com>

**Rails 8 Modernization (derivative work):**
Copyright © 2025 Launch Scout, LLC

Both the original work and this derivative work are distributed under the MIT License.

See the [original project](https://github.com/brobertsaz/railscrm) for the original source code.

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

## Support

For issues, questions, or contributions, please use the GitHub issue tracker.
