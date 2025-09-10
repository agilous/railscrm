require 'rails_helper'

RSpec.describe Opportunity, type: :model do
  subject(:opportunity) { build(:opportunity) }

  describe 'validations' do
    it { is_expected.to validate_presence_of(:opportunity_name) }
    it { is_expected.to validate_presence_of(:account_name) }
    it { is_expected.to validate_presence_of(:owner) }
  end

  describe '.types' do
    it 'returns array of opportunity type options' do
      types = Opportunity.types

      expect(types).to eq([ [ 'New Customer', 'new_customer' ], [ 'Existing Customer', 'existing_customer' ] ])
    end
  end

  describe '.stages' do
    it 'returns array of stage options' do
      stages = Opportunity.stages

      expected_stages = [
        [ 'Prospecting', 'prospecting' ],
        [ 'Proposal', 'proposal' ],
        [ 'Analysis', 'analysis' ],
        [ 'Presentation', 'presentation' ],
        [ 'Negotiation', 'negotiation' ],
        [ 'Final Review', 'final_review' ],
        [ 'Closed/Won', 'closed_won' ],
        [ 'Closed/Lost', 'closed_lost' ]
      ]

      expect(stages).to eq(expected_stages)
    end
  end

  describe 'stage progression traits' do
    it 'can be created in proposal stage' do
      opportunity = build(:opportunity, :proposal_stage)

      expect(opportunity.stage).to eq('proposal')
      expect(opportunity.probability).to eq(50)
    end

    it 'can be created in negotiation stage' do
      opportunity = build(:opportunity, :negotiation_stage)

      expect(opportunity.stage).to eq('negotiation')
      expect(opportunity.probability).to eq(75)
    end

    it 'can be created as closed won' do
      opportunity = build(:opportunity, :closed_won)

      expect(opportunity.stage).to eq('closed_won')
      expect(opportunity.probability).to eq(100)
    end

    it 'can be created as closed lost' do
      opportunity = build(:opportunity, :closed_lost)

      expect(opportunity.stage).to eq('closed_lost')
      expect(opportunity.probability).to eq(0)
    end
  end

  describe 'opportunity type traits' do
    it 'defaults to new customer type' do
      opportunity = build(:opportunity)

      expect(opportunity.type).to eq('new_customer')
    end

    it 'can be created for existing customer' do
      opportunity = build(:opportunity, :existing_customer)

      expect(opportunity.type).to eq('existing_customer')
    end
  end

  describe 'amount traits' do
    it 'has default amount' do
      opportunity = build(:opportunity)

      expect(opportunity.amount).to eq(10000.00)
    end

    it 'can be created as large deal' do
      opportunity = build(:opportunity, :large_deal)

      expect(opportunity.amount).to eq(100000.00)
    end
  end

  describe 'complete opportunity data' do
    it 'can store all opportunity fields' do
      opportunity = create(:opportunity,
                          opportunity_name: 'Big Deal',
                          account_name: 'Major Corp',
                          amount: 50000.00,
                          stage: 'negotiation',
                          owner: 'Sales Manager',
                          probability: 80,
                          closing_date: Date.current + 15.days,
                          contact_name: 'Sales Contact',
                          type: 'existing_customer',
                          comments: 'Important renewal opportunity')

      expect(opportunity).to be_valid
      expect(opportunity.opportunity_name).to eq('Big Deal')
      expect(opportunity.account_name).to eq('Major Corp')
      expect(opportunity.amount).to eq(50000.00)
      expect(opportunity.stage).to eq('negotiation')
      expect(opportunity.owner).to eq('Sales Manager')
      expect(opportunity.probability).to eq(80)
      expect(opportunity.closing_date).to eq(Date.current + 15.days)
      expect(opportunity.contact_name).to eq('Sales Contact')
      expect(opportunity.type).to eq('existing_customer')
      expect(opportunity.comments).to eq('Important renewal opportunity')
    end
  end

  describe 'date handling' do
    it 'properly handles closing date' do
      future_date = 45.days.from_now.to_date
      opportunity = build(:opportunity, closing_date: future_date)

      expect(opportunity.closing_date).to eq(future_date)
    end
  end
end
