# Pipedrive Synchronization

This Wendell CRM application includes a Pipedrive synchronization feature to import data from your Pipedrive account.

## Setup

1. **Install dependencies**
   ```bash
   bundle install
   ```

2. **Configure API credentials**
   - Copy `.env.example` to `.env`
   - Add your Pipedrive API token and company domain:
   ```
   PIPEDRIVE_API_TOKEN=your_actual_api_token_here
   PIPEDRIVE_COMPANY_DOMAIN=yourcompany.pipedrive.com
   ```

   To get your API token:
   - Log into Pipedrive
   - Go to Settings > Personal preferences > API
   - Copy your personal API token

3. **Run database migrations**
   ```bash
   bundle exec rails db:migrate
   ```

## Data Mapping

The sync maps Pipedrive entities to Rails models as follows:

| Pipedrive Entity | Rails Model | Notes |
|-----------------|-------------|-------|
| Users | User | Creates users with random passwords |
| Organizations | Account | Company/organization records |
| Persons | Contact or Lead | Persons with deals become Contacts, others become Leads |
| Deals | Opportunity | Sales opportunities |
| Activities | Task | To-do items and activities |
| Notes | Note | Attached to relevant entities |

## Running the Sync

### Full Sync
Sync all data from Pipedrive:
```bash
bundle exec rails pipedrive:sync
```

### Partial Syncs
You can sync specific entity types:

```bash
# Sync only users
bundle exec rails pipedrive:sync_users

# Sync only organizations/accounts
bundle exec rails pipedrive:sync_organizations

# Sync only persons (contacts/leads)
bundle exec rails pipedrive:sync_persons

# Sync only deals/opportunities
bundle exec rails pipedrive:sync_deals

# Sync only activities/tasks
bundle exec rails pipedrive:sync_activities
```

### View Statistics
Check sync statistics:
```bash
bundle exec rails pipedrive:stats
```

### Clear Mappings
Clear all Pipedrive ID mappings (use with caution):
```bash
bundle exec rails pipedrive:clear_mappings
```

## How It Works

1. **ID Mapping**: The sync maintains a mapping between Pipedrive IDs and Rails record IDs in the `pipedrive_mappings` table
2. **Incremental Updates**: Existing records are updated rather than duplicated
3. **Pagination**: Large datasets are fetched in batches of 100 records
4. **Relationships**: The sync preserves relationships between entities (e.g., deals linked to organizations)

## Scheduling Regular Syncs

To run the sync regularly, you can:

1. **Using cron (with whenever gem)**:
   Add to your `Gemfile`:
   ```ruby
   gem 'whenever', require: false
   ```
   
   Create `config/schedule.rb`:
   ```ruby
   every 1.hour do
     rake "pipedrive:sync"
   end
   ```

2. **Using Heroku Scheduler** (if deployed to Heroku):
   Add the task `rails pipedrive:sync` to run hourly

3. **Manual scheduling**:
   Run the sync manually when needed

## Troubleshooting

1. **Authentication errors**: Verify your API token is correct
2. **Missing data**: Check that your Pipedrive user has access to the data
3. **Duplicate records**: The sync uses email/name matching to prevent duplicates
4. **Failed validations**: Check Rails model validations match your data

## Customization

The sync script (`lib/pipedrive_sync.rb`) can be customized to:
- Map additional custom fields
- Change the matching logic
- Add data transformations
- Skip certain records

## Security Notes

- Never commit `.env` files with real API tokens
- Use environment variables in production
- Restrict API token permissions in Pipedrive if possible
- Consider rate limiting for large datasets