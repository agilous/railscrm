require 'rails_helper'

RSpec.describe ApplicationHelper, type: :helper do
  describe '#sortable_header' do
    let(:mock_request) { double('request') }
    let(:base_params) { { 'name' => 'John', 'status' => 'new' } }

    before do
      allow(helper).to receive(:request).and_return(mock_request)
      allow(mock_request).to receive(:query_parameters).and_return(base_params)
      allow(helper).to receive(:leads_path) { |params| "/leads?#{params.to_query}" }
      allow(helper).to receive(:controller_name).and_return('leads')
    end

    context 'when column is not currently sorted' do
      it 'generates ascending sort link by default' do
        result = helper.sortable_header('first_name', 'Name')

        expect(result).to include('href="/leads?')
        expect(result).to include('sort=first_name')
        expect(result).to include('direction=asc')
        expect(result).to include('Name')
      end

      it 'preserves existing query parameters' do
        result = helper.sortable_header('first_name', 'Name')

        expect(result).to include('name=John')
        expect(result).to include('status=new')
      end

      it 'shows invisible arrow that appears on hover' do
        result = helper.sortable_header('first_name', 'Name')

        expect(result).to include('invisible group-hover:visible group-focus:visible')
        expect(result).to include('<svg')
      end
    end

    context 'when column is currently sorted ascending' do
      it 'generates descending sort link' do
        result = helper.sortable_header('first_name', 'Name',
                                      current_sort: 'first_name',
                                      current_direction: 'asc')

        expect(result).to include('sort=first_name')
        expect(result).to include('direction=desc')
      end

      it 'shows rotated arrow for ascending sort' do
        result = helper.sortable_header('first_name', 'Name',
                                      current_sort: 'first_name',
                                      current_direction: 'asc')

        expect(result).to include('rotate-180')
        expect(result).to include('<svg')
        expect(result).not_to include('invisible')
      end
    end

    context 'when column is currently sorted descending' do
      it 'generates ascending sort link' do
        result = helper.sortable_header('first_name', 'Name',
                                      current_sort: 'first_name',
                                      current_direction: 'desc')

        expect(result).to include('sort=first_name')
        expect(result).to include('direction=asc')
      end

      it 'shows normal arrow for descending sort' do
        result = helper.sortable_header('first_name', 'Name',
                                      current_sort: 'first_name',
                                      current_direction: 'desc')

        expect(result).not_to include('rotate-180')
        expect(result).to include('<svg')
        expect(result).not_to include('invisible')
      end
    end

    context 'with different column names and titles' do
      it 'handles company column' do
        result = helper.sortable_header('company', 'Company Name')

        expect(result).to include('sort=company')
        expect(result).to include('Company Name')
      end

      it 'handles created_at column' do
        result = helper.sortable_header('created_at', 'Created')

        expect(result).to include('sort=created_at')
        expect(result).to include('Created')
      end

      it 'handles assigned_to column' do
        result = helper.sortable_header('assigned_to', 'Assigned To')

        expect(result).to include('sort=assigned_to')
        expect(result).to include('Assigned To')
      end
    end

    context 'HTML structure and CSS classes' do
      it 'includes proper CSS classes for styling' do
        result = helper.sortable_header('first_name', 'Name')

        expect(result).to include('group inline-flex items-center hover:text-gray-900')
        expect(result).to include('ml-2 flex-none rounded text-gray-400')
      end

      it 'includes proper SVG structure' do
        result = helper.sortable_header('first_name', 'Name')

        expect(result).to include('<svg class="h-5 w-5"')
        expect(result).to include('viewBox="0 0 20 20"')
        expect(result).to include('fill="currentColor"')
        expect(result).to include('aria-hidden="true"')
      end

      it 'generates valid HTML link' do
        result = helper.sortable_header('first_name', 'Name')

        expect(result).to match(/<a[^>]*href="[^"]*"[^>]*>/)
        expect(result).to match(/<\/a>$/)
      end
    end

    context 'edge cases' do
      it 'handles empty query parameters' do
        allow(mock_request).to receive(:query_parameters).and_return({})

        result = helper.sortable_header('first_name', 'Name')

        expect(result).to include('sort=first_name')
        expect(result).to include('direction=asc')
      end

      it 'handles nil current_sort and current_direction' do
        result = helper.sortable_header('first_name', 'Name',
                                      current_sort: nil,
                                      current_direction: nil)

        expect(result).to include('direction=asc')
        expect(result).to include('invisible')
      end

      it 'handles HTML-unsafe title text' do
        result = helper.sortable_header('first_name', 'Name & Title')

        expect(result).to include('Name & Title')
        # Should be properly escaped in the HTML
      end
    end

    describe 'integration with leads controller' do
      it 'matches expected columns from leads controller' do
        allowed_columns = %w[first_name last_name email company lead_status assigned_to created_at]

        allowed_columns.each do |column|
          result = helper.sortable_header(column, column.humanize)
          expect(result).to include("sort=#{column}")
        end
      end

      it 'preserves filter parameters that would be used in leads index' do
        filter_params = {
          'name' => 'John Doe',
          'company' => 'Acme Corp',
          'status' => 'new',
          'assigned_to' => '123',
          'created_since' => '2024-01-01',
          'created_before' => '2024-12-31'
        }

        allow(mock_request).to receive(:query_parameters).and_return(filter_params)

        result = helper.sortable_header('first_name', 'Name')

        filter_params.each do |key, value|
          # URLs are HTML escaped, so we need to check for the encoded version
          encoded_value = CGI.escape(value.to_s)
          expect(result).to include("#{key}=#{encoded_value}")
        end
      end
    end
  end
end
