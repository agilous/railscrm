class Opportunity < ApplicationRecord
  # Disable single-table inheritance for the 'type' column
  self.inheritance_column = nil

  validates_presence_of :opportunity_name, :account_name, :owner

  TYPES = [ [ "New Customer", "new_customer" ], [ "Existing Customer", "existing_customer" ] ]
  STAGES = [ [ "Prospecting", "prospecting" ], [ "Proposal", "proposal" ], [ "Analysis", "analysis" ],
            [ "Presentation", "presentation" ], [ "Negotiation", "negotiation" ], [ "Final Review", "final_review" ],
            [ "Closed/Won", "closed_won" ], [ "Closed/Lost", "closed_lost" ] ]

  # Filtering scopes
  scope :by_name, ->(name) { where("opportunity_name ILIKE :name", name: "%#{Opportunity.sanitize_sql_like(name)}%") }
  scope :by_account, ->(account) { where("account_name ILIKE :account", account: "%#{Opportunity.sanitize_sql_like(account)}%") }
  scope :by_owner, ->(owner) { where("owner ILIKE :owner", owner: "%#{Opportunity.sanitize_sql_like(owner)}%") }
  scope :by_stage, ->(stage) { where(stage: stage) }
  scope :by_type, ->(type) { where(type: type) }
  scope :created_since, ->(date) { where("created_at >= ?", date) }
  scope :created_before, ->(date) { where("created_at <= ?", date) }
  scope :closing_after, ->(date) { where("closing_date >= ?", date) }
  scope :closing_before, ->(date) { where("closing_date <= ?", date) }

  class << self
    def types
      TYPES
    end

    def stages
      STAGES
    end
  end
end
