require_relative "../pipedrive_sync"

namespace :pipedrive do
  desc "One-time production migration from Pipedrive to RailsCRM"
  task migrate: :environment do
    start_time = Time.current

    puts "\n" + "=" * 80
    puts " PIPEDRIVE → RAILSCRM ONE-TIME MIGRATION"
    puts "=" * 80
    puts " Started: #{start_time}"
    puts "=" * 80

    begin
      # Run the migration
      puts "\nStarting data migration..."
      sync = PipedriveSync.new
      sync.sync_all

      # Show results
      puts "\n" + "=" * 80
      puts " MIGRATION RESULTS"
      puts "=" * 80

      PipedriveMapping.group(:pipedrive_type).count.each do |type, count|
        puts "  #{type.ljust(15)}: #{count.to_s.rjust(6)}"
      end

      duration = ((Time.current - start_time) / 60).round(1)
      puts "=" * 80
      puts " Duration: #{duration} minutes"
      puts " Completed: #{Time.current}"
      puts "=" * 80

    rescue => e
      puts "\n[ERROR] Migration failed: #{e.message}"
      puts e.backtrace.first(10).join("\n")
      exit 1
    end
  end

  desc "Show migration statistics"
  task stats: :environment do
    puts "\n=== Pipedrive Migration Status ==="
    puts "Total mappings: #{PipedriveMapping.count}"

    PipedriveMapping.group(:pipedrive_type).count.each do |type, count|
      puts "  #{type.ljust(15)}: #{count.to_s.rjust(6)}"
    end

    puts "\n=== Rails CRM Data ==="
    puts "  Users          : #{User.count.to_s.rjust(6)}"
    puts "  Accounts       : #{Account.count.to_s.rjust(6)}"
    puts "  Contacts       : #{Contact.count.to_s.rjust(6)}"
    puts "  Leads          : #{Lead.count.to_s.rjust(6)}"
    puts "  Opportunities  : #{Opportunity.count.to_s.rjust(6)}"
    puts "  Tasks          : #{Task.count.to_s.rjust(6)}"
    puts "  Notes          : #{Note.count.to_s.rjust(6)}"
  end
end
