namespace :leads do
  desc "Fix lead assignments based on lead_owner email"
  task fix_assignments: :environment do
    puts "Fixing lead assignments..."

    fixed_count = 0
    not_found_owners = Set.new

    Lead.find_each do |lead|
      if lead.lead_owner.present?
        user = User.find_by(email: lead.lead_owner)

        if user && lead.assigned_to_id != user.id
          lead.update!(assigned_to: user)
          fixed_count += 1
          print "."
        elsif user.nil?
          not_found_owners.add(lead.lead_owner)
        end
      end
    end

    puts "\n\nFixed #{fixed_count} lead assignments"

    if not_found_owners.any?
      puts "\nOwners not found in users table:"
      not_found_owners.each { |owner| puts "  - #{owner}" }
    end
  end

  desc "Update lead statuses based on activity"
  task update_statuses: :environment do
    puts "Updating lead statuses..."

    # For now, we'll set some random statuses for demonstration
    # In production, this would pull from Pipedrive API

    status_options = [ "new", "contacted", "qualified", "disqualified" ]
    weights = [ 0.5, 0.3, 0.15, 0.05 ] # Weighted probability

    updated_count = 0

    Lead.where(lead_status: "new").find_each do |lead|
      # Simulate status based on some criteria
      # In real scenario, this would check Pipedrive API for activities

      # For demo: older leads are more likely to have been contacted
      days_old = (Time.current - lead.created_at) / 1.day

      if days_old > 30
        new_status = [ "contacted", "qualified", "disqualified" ].sample
      elsif days_old > 7
        new_status = [ "new", "contacted" ].sample
      else
        new_status = "new"
      end

      if lead.lead_status != new_status
        lead.update!(lead_status: new_status)
        updated_count += 1
        print "."
      end
    end

    puts "\n\nUpdated #{updated_count} lead statuses"

    puts "\nStatus distribution:"
    Lead.group(:lead_status).count.each do |status, count|
      puts "  #{status}: #{count}"
    end
  end
end
