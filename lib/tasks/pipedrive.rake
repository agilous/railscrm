require_relative "../pipedrive_sync"

namespace :pipedrive do
  desc "Sync all data from Pipedrive to Rails CRM"
  task sync: :environment do
    puts "Starting Pipedrive sync..."

    begin
      sync = PipedriveSync.new
      sync.sync_all
      puts "Sync completed successfully!"
    rescue => e
      puts "Error during sync: #{e.message}"
      puts e.backtrace.join("\n")
    end
  end

  desc "Sync only users from Pipedrive"
  task sync_users: :environment do
    puts "Syncing users from Pipedrive..."

    begin
      sync = PipedriveSync.new
      sync.sync_users
      puts "User sync completed!"
    rescue => e
      puts "Error syncing users: #{e.message}"
    end
  end

  desc "Sync only organizations from Pipedrive"
  task sync_organizations: :environment do
    puts "Syncing organizations from Pipedrive..."

    begin
      sync = PipedriveSync.new
      sync.sync_organizations
      puts "Organization sync completed!"
    rescue => e
      puts "Error syncing organizations: #{e.message}"
    end
  end

  desc "Sync only persons from Pipedrive"
  task sync_persons: :environment do
    puts "Syncing persons from Pipedrive..."

    begin
      sync = PipedriveSync.new
      sync.sync_persons
      puts "Person sync completed!"
    rescue => e
      puts "Error syncing persons: #{e.message}"
    end
  end

  desc "Sync only deals from Pipedrive"
  task sync_deals: :environment do
    puts "Syncing deals from Pipedrive..."

    begin
      sync = PipedriveSync.new
      sync.sync_deals
      puts "Deal sync completed!"
    rescue => e
      puts "Error syncing deals: #{e.message}"
    end
  end

  desc "Sync only activities from Pipedrive"
  task sync_activities: :environment do
    puts "Syncing activities from Pipedrive..."

    begin
      sync = PipedriveSync.new
      sync.sync_activities
      puts "Activity sync completed!"
    rescue => e
      puts "Error syncing activities: #{e.message}"
    end
  end

  desc "Clear all Pipedrive mappings (use with caution)"
  task clear_mappings: :environment do
    print "Are you sure you want to clear all Pipedrive mappings? (yes/no): "
    input = STDIN.gets.chomp

    if input.downcase == "yes"
      PipedriveMapping.destroy_all
      puts "All Pipedrive mappings have been cleared."
    else
      puts "Operation cancelled."
    end
  end

  desc "Show sync statistics"
  task stats: :environment do
    puts "\n=== Pipedrive Sync Statistics ==="
    puts "Total mappings: #{PipedriveMapping.count}"

    PipedriveMapping.distinct.pluck(:pipedrive_type).each do |type|
      count = PipedriveMapping.where(pipedrive_type: type).count
      puts "  #{type}: #{count}"
    end

    puts "\n=== Rails CRM Statistics ==="
    puts "  Users: #{User.count}"
    puts "  Accounts: #{Account.count}"
    puts "  Contacts: #{Contact.count}"
    puts "  Leads: #{Lead.count}"
    puts "  Opportunities: #{Opportunity.count}"
    puts "  Tasks: #{Task.count}"
    puts "  Notes: #{Note.count}"
  end
end
