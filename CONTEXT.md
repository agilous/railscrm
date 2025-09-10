# Rails CRM Migration Context

## Overview
This is a **Rails 8 modernization** of an older Rails 3.2.11 CRM application. The original project is located at `/Users/bbarnett/src/agilous/railscrm` and uses MongoDB with Mongoid. This modern version uses PostgreSQL with ActiveRecord.

## What Has Been Completed

### ✅ Infrastructure & Setup
- Created new Rails 8.0 project with PostgreSQL database
- Added essential gems: `devise`, `bootstrap`, `sassc-rails`, `jquery-rails`
- Set up database and ran all migrations successfully
- Configured modern Ruby 3.2.1 environment

### ✅ Models Migration (Mongoid → ActiveRecord)
All models have been migrated and are fully functional:

**User Model (`app/models/user.rb`)**
- Devise authentication with trackable enabled
- Approval workflow: `approved` boolean field with custom Devise methods
- Admin functionality: `admin` boolean field
- Additional fields: `first_name`, `last_name`, `company`, `phone`
- Method: `full_name` helper
- Association: `has_many :leads`

**Contact Model (`app/models/contact.rb`)**
- Fields: `first_name`, `last_name`, `company`, `email`, `phone`, address fields
- Validations: email format, presence validations, email uniqueness
- Method: `full_name` helper

**Lead Model (`app/models/lead.rb`)**
- Inherits Contact fields (composition over inheritance approach)
- Additional fields: `interested_in`, `comments`, `lead_status`, `lead_source`, etc.
- Constants: `STATUS`, `SOURCES`, `INTERESTS` arrays with class methods
- Associations: `belongs_to :assigned_to` (User), `has_many :notes`
- Nested attributes for notes with `allow_destroy`

**Account Model (`app/models/account.rb`)**
- Fields: `name`, `email`, `website`, `phone`, address fields
- Validations: name presence/uniqueness, phone presence

**Opportunity Model (`app/models/opportunity.rb`)**
- Fields: `opportunity_name`, `account_name`, `amount`, `stage`, `owner`, etc.
- Constants: `TYPES`, `STAGES` arrays with class methods
- Validations: presence of key fields

**Note Model (`app/models/note.rb`)**
- Polymorphic association: `belongs_to :notable`
- Field: `content` (text)
- Validation: content presence

**Task Model (`app/models/task.rb`)**
- Fields: `title`, `description`, `due_date`, `completed`, `priority`
- Association: `belongs_to :assignee` (User)
- Scopes: `completed`, `pending`

### ✅ Database Schema
All migrations completed successfully:
- Users table with Devise fields + custom fields
- Foreign key constraints properly configured
- Polymorphic associations for notes
- Unique indexes on key fields (email, name)

### ✅ Routes Configuration (`config/routes.rb`)
Fully migrated routing structure:
- Devise routes with custom paths (`login`, `logout`, `signup`)
- Admin routes (`dashboard`, `admin`)
- Web-to-lead functionality routes
- All resource routes for CRM entities
- Lead conversion and user approval routes

## What Still Needs to be Done

### 🔄 Next Steps (In Priority Order)

1. **Controllers Migration**
   - Copy and adapt controllers from `/Users/bbarnett/src/agilous/railscrm/app/controllers/`
   - Update for Rails 8 conventions (strong parameters, etc.)
   - Key controllers: `PagesController`, `LeadsController`, `UsersController`, etc.

2. **Views Migration**
   - Copy and adapt views from `/Users/bbarnett/src/agilous/railscrm/app/views/`
   - Update from Rails 3 ERB to modern Rails 8
   - Convert from Twitter Bootstrap 2 to Bootstrap 5
   - Update form helpers and link helpers

3. **Assets & Styling**
   - Migrate CSS/SCSS from `/Users/bbarnett/src/agilous/railscrm/app/assets/`
   - Update JavaScript for modern Rails (Stimulus, Turbo)
   - Configure Bootstrap 5 properly

4. **Testing & Validation**
   - Test user authentication and approval workflow
   - Test CRUD operations for all models
   - Test web-to-lead functionality
   - Verify lead conversion process

## Key Technical Decisions Made

- **Database**: PostgreSQL instead of MongoDB for better Rails 8 integration
- **Authentication**: Kept Devise but updated to modern version
- **Models**: Used composition over inheritance (Lead has Contact fields vs inherits from Contact)
- **Associations**: Proper ActiveRecord foreign keys instead of Mongoid references
- **Validation**: Updated to modern Rails validation syntax

## File Locations

**Original Project**: `/Users/bbarnett/src/agilous/railscrm/`
**New Project**: `/Users/bbarnett/src/agilous/railscrm-modern/` (current directory)

## Commands for Development

```bash
# Start server
rails server

# Console
rails console

# Run migrations
rails db:migrate

# Reset database
rails db:drop db:create db:migrate

# Generate controller
rails generate controller ControllerName

# Run tests
rails test
```

## Important Notes

- All models are working and tested via Rails console
- Database schema matches original functionality
- Routes are configured for all original features
- Ready for controller and view migration
- User approval workflow is implemented and functional
- Foreign key relationships are properly established

The foundation is solid - just need to add the presentation layer (controllers/views) to make it fully functional!