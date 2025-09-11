require "httparty"
require "dotenv"
Dotenv.load

class PipedriveSync
  include HTTParty

  def initialize
    @api_token = ENV["PIPEDRIVE_API_TOKEN"]
    @company_domain = ENV["PIPEDRIVE_COMPANY_DOMAIN"]

    raise "Missing PIPEDRIVE_API_TOKEN environment variable" if @api_token.blank?
    raise "Missing PIPEDRIVE_COMPANY_DOMAIN environment variable" if @company_domain.blank?

    self.class.base_uri "https://#{@company_domain}/api/v1"
    @headers = {
      "Content-Type" => "application/json",
      "Accept" => "application/json"
    }
  end

  # Main sync method
  def sync_all
    puts "\n=== Starting Pipedrive Sync ==="

    sync_users
    sync_organizations
    sync_persons
    sync_deals
    sync_activities
    sync_notes

    puts "\n=== Sync Complete ==="
  end

  # Sync Pipedrive Users to Rails Users
  def sync_users
    puts "\n--- Syncing Users ---"

    response = self.class.get("/users",
      headers: @headers,
      query: { api_token: @api_token }
    )

    if response.success? && response["data"]
      response["data"].each do |pipedrive_user|
        sync_user(pipedrive_user)
      end
      puts "Synced #{response['data'].count} users"
    else
      puts "Error fetching users: #{response['error']}" if response["error"]
    end
  end

  # Sync Pipedrive Organizations to Rails Accounts
  def sync_organizations
    puts "\n--- Syncing Organizations to Accounts ---"

    start = 0
    limit = 100
    total_synced = 0

    loop do
      response = self.class.get("/organizations",
        headers: @headers,
        query: {
          api_token: @api_token,
          start: start,
          limit: limit
        }
      )

      break unless response.success? && response["data"]

      response["data"].each do |org|
        sync_organization(org)
        total_synced += 1
      end

      break unless response["additional_data"] && response["additional_data"]["pagination"] &&
                   response["additional_data"]["pagination"]["more_items_in_collection"]

      start += limit
    end

    puts "Synced #{total_synced} organizations"
  end

  # Sync Pipedrive Persons to Rails Contacts
  def sync_persons
    puts "\n--- Syncing Persons to Contacts ---"

    start = 0
    limit = 100
    total_synced = 0

    loop do
      response = self.class.get("/persons",
        headers: @headers,
        query: {
          api_token: @api_token,
          start: start,
          limit: limit
        }
      )

      break unless response.success? && response["data"]

      response["data"].each do |person|
        sync_person(person)
        total_synced += 1
      end

      break unless response["additional_data"] && response["additional_data"]["pagination"] &&
                   response["additional_data"]["pagination"]["more_items_in_collection"]

      start += limit
    end

    puts "Synced #{total_synced} persons"
  end

  # Sync Pipedrive Deals to Rails Opportunities
  def sync_deals
    puts "\n--- Syncing Deals to Opportunities ---"

    start = 0
    limit = 100
    total_synced = 0

    loop do
      response = self.class.get("/deals",
        headers: @headers,
        query: {
          api_token: @api_token,
          start: start,
          limit: limit
        }
      )

      break unless response.success? && response["data"]

      response["data"].each do |deal|
        sync_deal(deal)
        total_synced += 1
      end

      break unless response["additional_data"] && response["additional_data"]["pagination"] &&
                   response["additional_data"]["pagination"]["more_items_in_collection"]

      start += limit
    end

    puts "Synced #{total_synced} deals"
  end

  # Sync Pipedrive Activities to Rails Tasks
  def sync_activities
    puts "\n--- Syncing Activities to Tasks ---"

    start = 0
    limit = 100
    total_synced = 0

    loop do
      response = self.class.get("/activities",
        headers: @headers,
        query: {
          api_token: @api_token,
          start: start,
          limit: limit
        }
      )

      break unless response.success? && response["data"]

      response["data"].each do |activity|
        sync_activity(activity)
        total_synced += 1
      end

      break unless response["additional_data"] && response["additional_data"]["pagination"] &&
                   response["additional_data"]["pagination"]["more_items_in_collection"]

      start += limit
    end

    puts "Synced #{total_synced} activities"
  end

  # Sync Pipedrive Notes
  def sync_notes
    puts "\n--- Syncing Notes ---"

    start = 0
    limit = 100
    total_synced = 0

    loop do
      response = self.class.get("/notes",
        headers: @headers,
        query: {
          api_token: @api_token,
          start: start,
          limit: limit
        }
      )

      break unless response.success? && response["data"]

      response["data"].each do |note|
        sync_note(note)
        total_synced += 1
      end

      break unless response["additional_data"] && response["additional_data"]["pagination"] &&
                   response["additional_data"]["pagination"]["more_items_in_collection"]

      start += limit
    end

    puts "Synced #{total_synced} notes"
  end

  private

  def sync_user(pipedrive_user)
    user = User.find_by(email: pipedrive_user["email"])

    if user.nil? && pipedrive_user["email"].present?
      user = User.new(
        email: pipedrive_user["email"],
        first_name: pipedrive_user["name"]&.split(" ")&.first,
        last_name: pipedrive_user["name"]&.split(" ")&.last,
        phone: pipedrive_user["phone"],
        password: SecureRandom.hex(10), # Generate random password
        approved: pipedrive_user["active_flag"]
      )

      if user.save
        puts "  Created user: #{user.email}"
      else
        puts "  Failed to create user: #{pipedrive_user['email']} - #{user.errors.full_messages.join(', ')}"
      end
    else
      # Update existing user
      if user && user.update(
        first_name: pipedrive_user["name"]&.split(" ")&.first || user.first_name,
        last_name: pipedrive_user["name"]&.split(" ")&.last || user.last_name,
        phone: pipedrive_user["phone"] || user.phone
      )
        puts "  Updated user: #{user.email}"
      end
    end

    # Store Pipedrive ID mapping for future reference
    store_pipedrive_mapping("User", pipedrive_user["id"], user&.id)
  end

  def sync_organization(org)
    account = Account.find_by(name: org["name"])

    if account.nil?
      account = Account.new(
        name: org["name"],
        phone: extract_phone(org) || "000-000-0000", # Default phone if missing
        email: extract_email(org),
        website: org["cc_email"],
        address: org["address"],
        assigned_to: map_owner_name(org["owner_id"])
      )

      if account.save
        # Update timestamps after save to preserve original Pipedrive dates
        original_created = org["add_time"] ? DateTime.parse(org["add_time"]) : account.created_at
        original_updated = org["update_time"] ? DateTime.parse(org["update_time"]) : account.updated_at

        account.update_columns(
          created_at: original_created,
          updated_at: original_updated
        )

        puts "  Created account: #{account.name} (original date: #{original_created.strftime('%Y-%m-%d')})"
      else
        puts "  Failed to create account: #{org['name']} - #{account.errors.full_messages.join(', ')}"
      end
    else
      # Update existing account
      if account.update(
        phone: extract_phone(org) || account.phone,
        email: extract_email(org) || account.email,
        website: org["cc_email"] || account.website,
        address: org["address"] || account.address
      )
        puts "  Updated account: #{account.name}"
      end
    end

    store_pipedrive_mapping("Account", org["id"], account&.id)
  end

  def sync_person(person)
    # First check if this should be a Lead or Contact based on Pipedrive data
    # If person has open deals or is marked as qualified, treat as Contact
    # Otherwise, treat as Lead

    email = extract_primary_email(person["email"])
    return unless email.present?

    # Check if person has deals
    has_deals = person["open_deals_count"].to_i > 0 || person["closed_deals_count"].to_i > 0

    if has_deals
      # Sync as Contact
      contact = Contact.find_by(email: email)

      if contact.nil?
        contact = Contact.new(
          first_name: person["first_name"] || person["name"]&.split(" ")&.first,
          last_name: person["last_name"] || person["name"]&.split(" ")&.last,
          email: email,
          phone: extract_primary_phone(person["phone"]),
          company: get_organization_name(person["org_id"])
        )

        if contact.save
          # Update timestamps after save to preserve original Pipedrive dates
          original_created = person["add_time"] ? DateTime.parse(person["add_time"]) : contact.created_at
          original_updated = person["update_time"] ? DateTime.parse(person["update_time"]) : contact.updated_at

          contact.update_columns(
            created_at: original_created,
            updated_at: original_updated
          )

          puts "  Created contact: #{contact.email} (original date: #{original_created.strftime('%Y-%m-%d')})"
        else
          puts "  Failed to create contact: #{email} - #{contact.errors.full_messages.join(', ')}"
        end
      else
        # Update existing contact
        if contact.update(
          first_name: person["first_name"] || contact.first_name,
          last_name: person["last_name"] || contact.last_name,
          phone: extract_primary_phone(person["phone"]) || contact.phone,
          company: get_organization_name(person["org_id"]) || contact.company
        )
          puts "  Updated contact: #{contact.email}"
        end
      end

      store_pipedrive_mapping("Contact", person["id"], contact&.id)
    else
      # Sync as Lead
      lead = Lead.find_by(email: email)

      # Map the owner to the correct user
      owner_email = map_owner_name(person["owner_id"])
      assigned_user = User.find_by(email: owner_email) if owner_email
      assigned_user ||= get_or_create_default_user

      if lead.nil? && assigned_user
        lead = Lead.new(
          first_name: person["first_name"] || person["name"]&.split(" ")&.first,
          last_name: person["last_name"] || person["name"]&.split(" ")&.last,
          email: email,
          phone: extract_primary_phone(person["phone"]),
          company: get_organization_name(person["org_id"]),
          lead_status: map_person_status(person),
          lead_source: "pipedrive",
          lead_owner: owner_email || assigned_user.email,
          assigned_to: assigned_user
        )

        if lead.save
          # Update timestamps after save to preserve original Pipedrive dates
          original_created = person["add_time"] ? DateTime.parse(person["add_time"]) : lead.created_at
          original_updated = person["update_time"] ? DateTime.parse(person["update_time"]) : lead.updated_at

          lead.update_columns(
            created_at: original_created,
            updated_at: original_updated
          )

          puts "  Created lead: #{lead.email} (original date: #{original_created.strftime('%Y-%m-%d')})"
        else
          puts "  Failed to create lead: #{email} - #{lead.errors.full_messages.join(', ')}"
        end
      elsif lead && assigned_user
        # Update existing lead
        if lead.update(
          first_name: person["first_name"] || lead.first_name,
          last_name: person["last_name"] || lead.last_name,
          phone: extract_primary_phone(person["phone"]) || lead.phone,
          company: get_organization_name(person["org_id"]) || lead.company,
          lead_status: map_person_status(person) || lead.lead_status,
          lead_owner: owner_email || lead.lead_owner,
          assigned_to: assigned_user
        )
          puts "  Updated lead: #{lead.email}"
        end
      end

      store_pipedrive_mapping("Lead", person["id"], lead&.id)
    end
  end

  def sync_deal(deal)
    opportunity = Opportunity.find_by(opportunity_name: deal["title"])

    # Map Pipedrive stage to our stages
    stage = map_deal_stage(deal["stage_id"], deal["status"])

    if opportunity.nil?
      opportunity = Opportunity.new(
        opportunity_name: deal["title"],
        account_name: get_organization_name(deal["org_id"]) || "Unknown",
        amount: deal["value"],
        stage: stage,
        owner: map_owner_name(deal["owner_id"]) || "admin",
        probability: deal["probability"],
        contact_name: get_person_name(deal["person_id"]),
        closing_date: deal["expected_close_date"] || deal["close_time"],
        type: "new_customer"
      )

      if opportunity.save
        # Update timestamps after save to preserve original Pipedrive dates
        original_created = deal["add_time"] ? DateTime.parse(deal["add_time"]) : opportunity.created_at
        original_updated = deal["update_time"] ? DateTime.parse(deal["update_time"]) : opportunity.updated_at

        opportunity.update_columns(
          created_at: original_created,
          updated_at: original_updated
        )

        puts "  Created opportunity: #{opportunity.opportunity_name} (original date: #{original_created.strftime('%Y-%m-%d')})"
      else
        puts "  Failed to create opportunity: #{deal['title']} - #{opportunity.errors.full_messages.join(', ')}"
      end
    else
      # Update existing opportunity
      if opportunity.update(
        amount: deal["value"] || opportunity.amount,
        stage: stage || opportunity.stage,
        probability: deal["probability"] || opportunity.probability,
        closing_date: deal["expected_close_date"] || deal["close_time"] || opportunity.closing_date
      )
        puts "  Updated opportunity: #{opportunity.opportunity_name}"
      end
    end

    store_pipedrive_mapping("Opportunity", deal["id"], opportunity&.id)
  end

  def sync_activity(activity)
    assignee = get_or_create_default_user
    return unless assignee

    task = Task.find_by(title: activity["subject"])

    if task.nil?
      task = Task.new(
        title: activity["subject"] || "Untitled Activity",
        description: activity["note"] || activity["type"],
        due_date: parse_activity_due_date(activity),
        completed: activity["done"],
        priority: activity["marked_as_done_time"] ? "low" : "medium",
        assignee: assignee
      )

      if task.save
        # Update timestamps after save to preserve original Pipedrive dates
        original_created = activity["add_time"] ? DateTime.parse(activity["add_time"]) : task.created_at
        original_updated = activity["update_time"] ? DateTime.parse(activity["update_time"]) : task.updated_at

        task.update_columns(
          created_at: original_created,
          updated_at: original_updated
        )

        puts "  Created task: #{task.title} (original date: #{original_created.strftime('%Y-%m-%d')})"
      else
        puts "  Failed to create task: #{activity['subject']} - #{task.errors.full_messages.join(', ')}"
      end
    else
      # Update existing task
      if task.update(
        description: activity["note"] || task.description,
        due_date: parse_activity_due_date(activity) || task.due_date,
        completed: activity["done"]
      )
        puts "  Updated task: #{task.title}"
      end
    end

    store_pipedrive_mapping("Task", activity["id"], task&.id)
  end

  def sync_note(note)
    # Notes in Pipedrive can be attached to deals, persons, or organizations
    # We'll attach them to the appropriate Rails model

    notable = find_notable_for_note(note)
    return unless notable

    rails_note = Note.find_by(
      content: note["content"],
      notable: notable
    )

    if rails_note.nil?
      rails_note = Note.new(
        content: note["content"],
        notable: notable
      )

      if rails_note.save
        puts "  Created note for #{notable.class.name}"
      else
        puts "  Failed to create note: #{rails_note.errors.full_messages.join(', ')}"
      end
    end

    store_pipedrive_mapping("Note", note["id"], rails_note&.id)
  end

  # Helper methods

  def extract_phone(org)
    # Pipedrive might store phones in custom fields
    org["phone"] || org["org_phone"]
  end

  def extract_email(org)
    # Pipedrive might store emails in custom fields
    org["email"] || org["cc_email"]
  end

  def extract_primary_email(email_data)
    return nil unless email_data

    if email_data.is_a?(Array)
      primary = email_data.find { |e| e["primary"] }
      primary ? primary["value"] : email_data.first["value"]
    elsif email_data.is_a?(String)
      email_data
    else
      email_data["value"]
    end
  end

  def extract_primary_phone(phone_data)
    return nil unless phone_data

    if phone_data.is_a?(Array)
      primary = phone_data.find { |p| p["primary"] }
      primary ? primary["value"] : phone_data.first["value"]
    elsif phone_data.is_a?(String)
      phone_data
    else
      phone_data["value"]
    end
  end

  def get_organization_name(org_data)
    return nil unless org_data

    # Handle both org_id as integer and as object with id field
    org_id = org_data.is_a?(Hash) ? org_data["id"] : org_data

    mapping = PipedriveMapping.find_by(
      pipedrive_type: "Organization",
      pipedrive_id: org_id
    )

    if mapping
      account = Account.find_by(id: mapping.rails_id)
      account&.name
    elsif org_data.is_a?(Hash) && org_data["name"]
      # If org data is already provided as object, use it directly
      org_data["name"]
    else
      # Fetch from API if not in mappings
      response = self.class.get("/organizations/#{org_id}",
        headers: @headers,
        query: { api_token: @api_token }
      )

      response["data"]["name"] if response.success? && response["data"]
    end
  end

  def get_person_name(person_data)
    return nil unless person_data

    # Handle both person_id as integer and as object with id field
    person_id = person_data.is_a?(Hash) ? person_data["id"] : person_data

    mapping = PipedriveMapping.find_by(
      pipedrive_type: "Person",
      pipedrive_id: person_id
    )

    if mapping
      # Could be either Contact or Lead
      contact = Contact.find_by(id: mapping.rails_id)
      return contact.full_name if contact

      lead = Lead.find_by(id: mapping.rails_id)
      lead.full_name if lead
    elsif person_data.is_a?(Hash) && person_data["name"]
      # If person data is already provided as object, use it directly
      person_data["name"]
    else
      # Fetch from API if not in mappings
      response = self.class.get("/persons/#{person_id}",
        headers: @headers,
        query: { api_token: @api_token }
      )

      response["data"]["name"] if response.success? && response["data"]
    end
  end

  def map_owner_name(owner_data)
    return nil unless owner_data

    # Handle both owner_id as integer and as object with id field
    owner_id = owner_data.is_a?(Hash) ? owner_data["id"] : owner_data

    mapping = PipedriveMapping.find_by(
      pipedrive_type: "User",
      pipedrive_id: owner_id
    )

    if mapping
      user = User.find_by(id: mapping.rails_id)
      user&.email
    elsif owner_data.is_a?(Hash) && owner_data["email"]
      # If owner data is already provided as object, use it directly
      owner_data["email"]
    else
      # Fetch from API if not in mappings
      response = self.class.get("/users/#{owner_id}",
        headers: @headers,
        query: { api_token: @api_token }
      )

      response["data"]["email"] if response.success? && response["data"]
    end
  end

  def map_deal_stage(stage_id, status)
    # If deal is won or lost, use those stages
    return "closed_won" if status == "won"
    return "closed_lost" if status == "lost"

    # Otherwise, we'd need to fetch pipeline stages from Pipedrive
    # For now, default to prospecting
    "prospecting"
  end

  def map_person_status(person)
    # Map Pipedrive person attributes to lead status
    # Check various indicators to determine status

    # If person has been contacted (has activities or emails)
    if person["activities_count"].to_i > 0 || person["email_messages_count"].to_i > 0
      # If they have open deals, they're qualified
      if person["open_deals_count"].to_i > 0
        "qualified"
      # If they have closed deals but no open ones, check if won or lost
      elsif person["closed_deals_count"].to_i > 0
        if person["won_deals_count"].to_i > 0
          "qualified"
        else
          "disqualified"
        end
      else
        "contacted"
      end
    else
      "new"
    end
  end

  def parse_activity_due_date(activity)
    if activity["due_date"] && activity["due_time"]
      DateTime.parse("#{activity['due_date']} #{activity['due_time']}")
    elsif activity["due_date"]
      Date.parse(activity["due_date"])
    else
      nil
    end
  end

  def find_notable_for_note(note)
    # Try to find the associated object for the note
    if note["deal_id"]
      mapping = PipedriveMapping.find_by(
        pipedrive_type: "Deal",
        pipedrive_id: note["deal_id"]
      )
      Opportunity.find_by(id: mapping.rails_id) if mapping
    elsif note["person_id"]
      mapping = PipedriveMapping.find_by(
        pipedrive_type: "Person",
        pipedrive_id: note["person_id"]
      )
      if mapping
        Lead.find_by(id: mapping.rails_id) || Contact.find_by(id: mapping.rails_id)
      end
    elsif note["org_id"]
      mapping = PipedriveMapping.find_by(
        pipedrive_type: "Organization",
        pipedrive_id: note["org_id"]
      )
      Account.find_by(id: mapping.rails_id) if mapping
    end
  end

  def get_or_create_default_user
    User.find_by(email: "admin@example.com") ||
    User.first ||
    User.create!(
      email: "admin@example.com",
      password: "password123",
      first_name: "Admin",
      last_name: "User",
      admin: true,
      approved: true
    )
  end

  def store_pipedrive_mapping(pipedrive_type, pipedrive_id, rails_id)
    return unless rails_id

    PipedriveMapping.find_or_create_by(
      pipedrive_type: pipedrive_type,
      pipedrive_id: pipedrive_id
    ) do |mapping|
      mapping.rails_id = rails_id
    end
  end

  # Helper methods for data extraction and parsing
  def parse_name(name)
    return [ "", "" ] if name.blank?

    parts = name.split(" ", 2)
    first_name = parts[0] || ""
    last_name = parts[1] || ""

    [ first_name, last_name ]
  end

  def extract_primary_email(email_data)
    return nil if email_data.blank?

    primary_email = email_data.find { |email| email["primary"] == true }
    return primary_email["value"] if primary_email

    # If no primary, return first email
    email_data.first&.dig("value")
  end

  def extract_primary_phone(phone_data)
    return nil if phone_data.blank?

    primary_phone = phone_data.find { |phone| phone["primary"] == true }
    return primary_phone["value"] if primary_phone

    # If no primary, return first phone
    phone_data.first&.dig("value")
  end
end

# PipedriveMapping model is defined in app/models/pipedrive_mapping.rb
