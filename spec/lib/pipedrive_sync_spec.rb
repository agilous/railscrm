require 'rails_helper'
require 'pipedrive_sync'

RSpec.describe PipedriveSync do
  let(:api_token) { 'test_token_123' }
  let(:company_domain) { 'test-company.pipedrive.com' }

  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with('PIPEDRIVE_API_TOKEN').and_return(api_token)
    allow(ENV).to receive(:[]).with('PIPEDRIVE_COMPANY_DOMAIN').and_return(company_domain)
  end

  describe 'initialization' do
    it 'sets up HTTParty base URI correctly' do
      sync = described_class.new
      expect(described_class.base_uri).to eq("https://#{company_domain}/api/v1")
    end

    it 'uses dummy values in test environment when API token is missing' do
      allow(ENV).to receive(:[]).with('PIPEDRIVE_API_TOKEN').and_return(nil)

      expect { described_class.new }.not_to raise_error
    end

    it 'uses dummy values in test environment when company domain is missing' do
      allow(ENV).to receive(:[]).with('PIPEDRIVE_COMPANY_DOMAIN').and_return(nil)

      expect { described_class.new }.not_to raise_error
    end

    it 'sets proper headers' do
      sync = described_class.new
      expect(sync.instance_variable_get(:@headers)).to eq({
        'Content-Type' => 'application/json',
        'Accept' => 'application/json'
      })
    end
  end

  describe '#sync_all' do
    let(:sync) { described_class.new }

    it 'calls all sync methods in correct order' do
      # Stub all the sync methods to prevent actual execution
      allow(sync).to receive(:sync_users)
      allow(sync).to receive(:sync_organizations)
      allow(sync).to receive(:sync_persons)
      allow(sync).to receive(:sync_deals)
      allow(sync).to receive(:sync_activities)
      allow(sync).to receive(:sync_notes)

      expect(sync).to receive(:sync_users).ordered
      expect(sync).to receive(:sync_organizations).ordered
      expect(sync).to receive(:sync_persons).ordered
      expect(sync).to receive(:sync_deals).ordered
      expect(sync).to receive(:sync_activities).ordered
      expect(sync).to receive(:sync_notes).ordered

      expect { sync.sync_all }.to output(/Starting Pipedrive Sync/).to_stdout
    end
  end

  describe '#sync_users' do
    let(:sync) { described_class.new }
    let(:pipedrive_users_response) do
      {
        'success' => true,
        'data' => [
          {
            'id' => 123,
            'name' => 'John Doe',
            'email' => 'john@example.com',
            'active_flag' => true
          },
          {
            'id' => 124,
            'name' => 'Jane Smith',
            'email' => 'jane@example.com',
            'active_flag' => false
          }
        ]
      }
    end

    before do
      allow(described_class).to receive(:get).and_return(
        double('response', success?: true, body: pipedrive_users_response.to_json).tap do |response|
          allow(response).to receive(:[]).with('data').and_return(pipedrive_users_response['data'])
          allow(response).to receive(:[]).with('success').and_return(true)
        end
      )
      # Stub the sync_user method to prevent actual user creation and output
      allow_any_instance_of(described_class).to receive(:sync_user)
    end

    it 'makes correct API call' do
      expect(described_class).to receive(:get).with(
        '/users',
        headers: sync.instance_variable_get(:@headers),
        query: { api_token: api_token }
      )

      # Suppress output during test execution
      allow($stdout).to receive(:puts)
      sync.sync_users
    end

    it 'processes each user from response' do
      # Stub the sync_user method to prevent actual user creation
      allow(sync).to receive(:sync_user)
      expect(sync).to receive(:sync_user).twice

      # Suppress output during test execution
      allow($stdout).to receive(:puts)
      sync.sync_users
    end
  end

  describe 'unit tests for core logic' do
    let(:sync) { described_class.new }

    describe 'name parsing' do
      it 'parses single name' do
        result = sync.send(:parse_name, 'John')
        expect(result).to eq([ 'John', '' ])
      end

      it 'parses full name' do
        result = sync.send(:parse_name, 'John Doe')
        expect(result).to eq([ 'John', 'Doe' ])
      end

      it 'parses complex name' do
        result = sync.send(:parse_name, 'John Michael Doe Jr.')
        expect(result).to eq([ 'John', 'Michael Doe Jr.' ])
      end
    end

    describe 'email extraction' do
      it 'extracts primary email' do
        email_data = [
          { 'value' => 'john@example.com', 'primary' => true },
          { 'value' => 'john@work.com', 'primary' => false }
        ]
        result = sync.send(:extract_primary_email, email_data)
        expect(result).to eq('john@example.com')
      end

      it 'extracts first email when no primary' do
        email_data = [
          { 'value' => 'john@example.com', 'primary' => false },
          { 'value' => 'john@work.com', 'primary' => false }
        ]
        result = sync.send(:extract_primary_email, email_data)
        expect(result).to eq('john@example.com')
      end

      it 'handles empty email data' do
        result = sync.send(:extract_primary_email, [])
        expect(result).to be_nil
      end
    end

    describe 'phone extraction' do
      it 'extracts primary phone' do
        phone_data = [
          { 'value' => '555-1234', 'primary' => true },
          { 'value' => '555-5678', 'primary' => false }
        ]
        result = sync.send(:extract_primary_phone, phone_data)
        expect(result).to eq('555-1234')
      end

      it 'extracts first phone when no primary' do
        phone_data = [
          { 'value' => '555-1234', 'primary' => false },
          { 'value' => '555-5678', 'primary' => false }
        ]
        result = sync.send(:extract_primary_phone, phone_data)
        expect(result).to eq('555-1234')
      end

      it 'handles empty phone data' do
        result = sync.send(:extract_primary_phone, [])
        expect(result).to be_nil
      end
    end
  end
end
