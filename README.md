# Rails CRM - Rails 8 Modernization

This is a **Rails 8 modernization** of the original [Rails CRM](https://github.com/brobertsaz/railscrm) opensource Customer Relations Management application. While the original project was built with Rails 3.2.11 and MongoDB, this version has been completely rewritten for Rails 8 with modern best practices and updated technologies.

## What's New in This Version

This modernized version includes significant upgrades:

- **Rails 8.0** with Ruby 3.2.1
- **PostgreSQL** database (replacing MongoDB/Mongoid)
- **Tailwind CSS** for modern, responsive UI (replacing Twitter Bootstrap)
- **ERB templates** (replacing HAML)
- **Pipedrive Integration** - Full bidirectional sync with Pipedrive CRM
- **Multi-association Notes System** - Attach notes to any entity (Leads, Contacts, Opportunities, etc.)
- **Comprehensive Test Suite** - RSpec, Capybara, and system tests
- **Modern JavaScript** - Stimulus controllers and Turbo
- **CI/CD Pipeline** - GitHub Actions for automated testing
- **Enhanced CRUD Operations** - Modern styling and improved user experience

See [PIPEDRIVE_SYNC.md](PIPEDRIVE_SYNC.md) for detailed Pipedrive integration documentation.

## About Rails CRM

Rails CRM is an opensource Customer Relations Management application intended to be similar to paid CRMs but as a bare bones solution that can be cloned and modified however you please.

This version maintains the core CRM functionality while leveraging modern Rails conventions and contemporary web development practices.

## Technology Stack

- **Ruby** 3.2.1
- **Rails** 8.0
- **Database** PostgreSQL
- **Authentication** Devise
- **Styling** Tailwind CSS
- **JavaScript** Stimulus, Turbo
- **Testing** RSpec, Capybara, Selenium WebDriver
- **API Integration** HTTParty (for Pipedrive sync)
- **Pagination** Kaminari

## Prerequisites

Before installing Rails CRM, ensure you have the following installed:

### PostgreSQL

Rails CRM uses PostgreSQL for its database. To install PostgreSQL:

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

### Ruby

This project uses Ruby 3.2.1. We recommend using a Ruby version manager:

**Using rbenv:**
```bash
rbenv install 3.2.1
rbenv local 3.2.1
```

**Using RVM:**
```bash
rvm install 3.2.1
rvm use 3.2.1
```

## Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/agilous/railscrm.git
   cd railscrm
   ```

2. **Install dependencies**
   ```bash
   gem install bundler
   bundle install
   ```

3. **Set up the database**
   ```bash
   rails db:create
   rails db:migrate
   ```

4. **(Optional) Configure Pipedrive Integration**

   If you want to sync with Pipedrive:
   ```bash
   cp .env.example .env
   # Edit .env and add your Pipedrive API credentials
   ```

   See [PIPEDRIVE_SYNC.md](PIPEDRIVE_SYNC.md) for detailed setup instructions.

5. **Start the Rails server**
   ```bash
   rails server
   ```

6. **Visit the application**

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

Rails CRM includes a web-to-lead function that generates embeddable forms for your website. When visitors submit these forms, new leads are automatically created in the CRM.

To use Web-to-Lead:

1. Go to **Leads** in the navigation
2. Click on **Web-to-Lead**
3. Configure your form:
   - Set a redirect URL (typically a "Thank You" page)
   - Select the fields you want to include
   - Click "Generate Form"
4. Copy the generated HTML code and paste it on your website

## Pipedrive Integration

This version includes comprehensive Pipedrive synchronization:

```bash
# Full sync of all data
rails pipedrive:sync

# Sync specific entities
rails pipedrive:sync_users
rails pipedrive:sync_organizations
rails pipedrive:sync_persons
rails pipedrive:sync_deals
rails pipedrive:sync_activities

# View sync statistics
rails pipedrive:stats
```

See [PIPEDRIVE_SYNC.md](PIPEDRIVE_SYNC.md) for complete documentation.

## Testing

Run the test suite:

```bash
# Run all tests
bundle exec rspec

# Run specific test file
bundle exec rspec spec/models/lead_spec.rb

# Run system tests
bundle exec rspec spec/system
```

## Development

```bash
# Start Rails server
rails server

# Open Rails console
rails console

# Run database migrations
rails db:migrate

# Reset database (caution: destroys all data)
rails db:drop db:create db:migrate

# Build Tailwind CSS
rails tailwindcss:build

# Watch Tailwind CSS for changes
rails tailwindcss:watch
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
- **Pipedrive Sync** - Bidirectional synchronization with Pipedrive
- **Modern UI** - Responsive design with Tailwind CSS
- **Comprehensive Testing** - Full test coverage with RSpec

## Project Structure

Key directories and files:

- `app/models/` - ActiveRecord models (User, Lead, Contact, Account, Opportunity, Task, Note)
- `app/controllers/` - Request handling and business logic
- `app/views/` - ERB templates
- `app/javascript/` - Stimulus controllers
- `spec/` - RSpec test suite
- `lib/pipedrive_sync.rb` - Pipedrive integration logic
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

Copyright © 2012 Bob Roberts <bob@rebel-outpost.com>
Rails 8 Modernization © 2024-2025

Distributed under the MIT License.
http://www.opensource.org/licenses/mit-license.php

## Support

For issues, questions, or contributions, please use the GitHub issue tracker.
