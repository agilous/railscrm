namespace :pipedrive do
  desc "Generate sample data mimicking Pipedrive structure"
  task sample_data: :environment do
    puts "Creating Pipedrive-style sample data..."

    # Create or find Dan Busken contact
    dan = Contact.find_or_create_by(email: "dan.busken@example.com") do |c|
      c.first_name = "Dan"
      c.last_name = "Busken"
      c.phone = "555-0123"
      c.company = "Busken Industries"
      c.address = "123 Main Street"
      c.city = "San Francisco"
      c.state = "CA"
      c.zip = "94105"
    end
    puts "Created/found contact: #{dan.full_name}"

    # Add notes to Dan
    dan.notes.create!(
      content: "Discussed potential partnership opportunities. Dan is interested in our enterprise solution and wants to schedule a follow-up demo next week."
    )

    dan.notes.create!(
      content: "Met at Tech Conference 2024. Very interested in API integration capabilities.",
      created_at: 2.weeks.ago
    )

    # Add activities for Dan
    dan.activities.create!(
      activity_type: "Meeting",
      title: "Initial Discovery Call",
      description: "Discuss business needs and product fit",
      due_date: 3.days.from_now,
      created_at: 1.week.ago
    )

    dan.activities.create!(
      activity_type: "Demo",
      title: "Product Demo - Enterprise Features",
      description: "Show advanced features and API capabilities",
      due_date: 1.week.from_now
    )

    dan.activities.create!(
      activity_type: "Call",
      title: "Follow-up call",
      description: "Check in after demo",
      due_date: 2.days.ago,
      completed_at: 1.day.ago,
      created_at: 1.week.ago
    )

    # Create an opportunity/deal for Dan
    opportunity = Opportunity.find_or_create_by(
      opportunity_name: "Busken Industries - Enterprise Plan",
      contact_name: dan.email
    ) do |o|
      o.account_name = "Busken Industries"
      o.amount = 50000
      o.stage = "negotiation"
      o.closing_date = 1.month.from_now
      o.probability = 75
    end
    puts "Created/found opportunity: #{opportunity.opportunity_name}"

    # Create additional sample contacts
    contacts_data = [
      {
        first_name: "Sarah",
        last_name: "Johnson",
        email: "sarah.johnson@techcorp.com",
        phone: "555-0124",
        company: "TechCorp Solutions",
        city: "New York",
        state: "NY"
      },
      {
        first_name: "Michael",
        last_name: "Chen",
        email: "mchen@innovate.io",
        phone: "555-0125",
        company: "Innovate.io",
        city: "Seattle",
        state: "WA"
      },
      {
        first_name: "Emily",
        last_name: "Rodriguez",
        email: "emily.r@startup.co",
        phone: "555-0126",
        company: "StartupCo",
        city: "Austin",
        state: "TX"
      }
    ]

    contacts_data.each do |contact_data|
      contact = Contact.find_or_create_by(email: contact_data[:email]) do |c|
        contact_data.each { |key, value| c.send("#{key}=", value) }
      end

      # Add some notes
      contact.notes.create!(
        content: "Initial contact made at industry event. Interested in learning more.",
        created_at: rand(1..30).days.ago
      )

      # Add some activities
      contact.activities.create!(
        activity_type: Activity::ACTIVITY_TYPES.sample,
        title: "Introductory #{[ 'Call', 'Meeting' ].sample}",
        description: "Get to know their business needs",
        due_date: rand(1..14).days.from_now,
        created_at: rand(1..7).days.ago
      )

      # Randomly add deals
      if rand > 0.5
        Opportunity.find_or_create_by(
          contact_name: contact.email,
          opportunity_name: "#{contact_data[:company]} - #{[ 'Starter', 'Professional', 'Enterprise' ].sample} Plan"
        ) do |o|
          o.account_name = contact_data[:company]
          o.amount = rand(5000..100000)
          o.stage = [ "prospecting", "qualification", "negotiation", "proposal" ].sample
          o.closing_date = rand(1..3).months.from_now
          o.probability = rand(25..90)
        end
      end

      puts "Created/found contact: #{contact.full_name}"
    end

    # Create some leads that haven't been converted
    leads_data = [
      {
        first_name: "Robert",
        last_name: "Smith",
        email: "rsmith@potential.com",
        phone: "555-0127",
        company: "Potential Corp"
      },
      {
        first_name: "Lisa",
        last_name: "Wong",
        email: "lwong@future.tech",
        phone: "555-0128",
        company: "Future Technologies"
      }
    ]

    leads_data.each do |lead_data|
      lead = Lead.find_or_create_by(email: lead_data[:email]) do |l|
        lead_data.each { |key, value| l.send("#{key}=", value) }
        l.lead_status = [ "new", "contacted", "qualified" ].sample
        l.lead_source = [ "web", "referral", "conference" ].sample
        l.lead_owner = "admin@example.com"
        # Set assigned_to to first user or nil
        l.assigned_to = User.first
      end

      # Add notes to leads only if the lead was saved successfully
      if lead.persisted?
        # Create note with multi-association system
        note_content = "Potential customer from #{lead.lead_source}. Need to qualify further."
        note = lead.notes.find_by(content: note_content)
        random_created_at = rand(1..14).days.ago
        if note
          note.update(created_at: random_created_at)
        else
          note = lead.notes.create!(
            content: note_content,
            created_at: random_created_at
          )
        end
        puts "Created/found lead: #{lead.full_name}"
      else
        puts "Failed to create lead: #{lead.errors.full_messages.join(', ')}"
      end
    end

    # Create some accounts
    accounts_data = [
      {
        name: "Busken Industries",
        phone: "555-0200",
        website: "www.busken.com",
        email: "info@busken.com",
        address: "123 Main Street",
        city: "San Francisco",
        state: "CA",
        zip: "94105"
      },
      {
        name: "TechCorp Solutions",
        phone: "555-0201",
        website: "www.techcorp.com",
        email: "contact@techcorp.com",
        address: "456 Park Avenue",
        city: "New York",
        state: "NY",
        zip: "10001"
      }
    ]

    accounts_data.each do |account_data|
      account = Account.find_or_create_by(email: account_data[:email]) do |a|
        account_data.each { |key, value| a.send("#{key}=", value) }
      end
      puts "Created/found account: #{account.name}"
    end

    # Create standalone tasks (if we have users)
    if User.any?
      task_data = [
        {
          title: "Review Q4 Pipeline",
          description: "Review all opportunities in the pipeline for Q4",
          due_date: 2.days.from_now,
          priority: "high",
          completed: false
        },
        {
          title: "Send follow-up emails",
          description: "Follow up with all leads contacted this week",
          due_date: Date.tomorrow,
          priority: "medium",
          completed: false
        },
        {
          title: "Prepare monthly report",
          description: "Compile metrics and prepare monthly sales report",
          due_date: 1.week.from_now,
          priority: "low",
          completed: false
        }
      ]

      task_data.each do |data|
        task = Task.find_or_create_by(title: data[:title]) do |t|
          data.each { |key, value| t.send("#{key}=", value) }
          t.assignee = User.first  # Assign to first user
        end
        puts "Created/found task: #{task.title}"
      end
    else
      puts "Skipping tasks - no users found"
    end

    puts "\n✅ Sample data creation complete!"
    puts "\nSummary:"
    puts "- Contacts: #{Contact.count}"
    puts "- Leads: #{Lead.count}"
    puts "- Accounts: #{Account.count}"
    puts "- Opportunities: #{Opportunity.count}"
    puts "- Notes: #{Note.count}"
    puts "- Activities: #{Activity.count}"
    puts "- Tasks: #{Task.count}"
  end

  desc "Clear all sample data (destructive)"
  task clear_sample_data: :environment do
    puts "⚠️  This will delete ALL data. Are you sure? Type 'yes' to confirm:"
    response = STDIN.gets.chomp

    if response.downcase == "yes"
      puts "Clearing all data..."
      Activity.destroy_all
      Note.destroy_all
      Task.destroy_all
      Opportunity.destroy_all
      Contact.destroy_all
      Lead.destroy_all
      Account.destroy_all
      puts "✅ All data cleared"
    else
      puts "Cancelled"
    end
  end
end
