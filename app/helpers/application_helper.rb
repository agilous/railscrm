module ApplicationHelper
  def safe_external_url(url)
    return nil if url.blank?

    # Ensure URL starts with http:// or https://
    normalized_url = url.start_with?("http://", "https://") ? url : "https://#{url}"

    # Parse and validate the URL
    begin
      uri = URI.parse(normalized_url)
      # Only allow http and https protocols
      return normalized_url if [ "http", "https" ].include?(uri.scheme)
    rescue URI::InvalidURIError
      # Return nil for invalid URLs
    end

    nil
  end

  def note_modal_html_attributes
    attrs = []
    attrs << "data-note-modal-contact-id=\"#{@contact.id}\"" if defined?(@contact) && @contact&.persisted?
    attrs << "data-note-modal-opportunity-id=\"#{@opportunity.id}\"" if defined?(@opportunity) && @opportunity&.persisted?
    attrs << "data-note-modal-account-id=\"#{@account.id}\"" if defined?(@account) && @account&.persisted?
    attrs << "data-note-modal-lead-id=\"#{@lead.id}\"" if defined?(@lead) && @lead&.persisted?
    attrs.join(" ").html_safe
  end

  def contact_related_account
    return nil unless @contact&.company.present?
    @contact_related_account ||= Account.find_by(name: @contact.company)
  end

  def opportunity_related_contact
    return nil unless @opportunity&.contact_name.present?
    @opportunity_related_contact ||= Contact.find_by(email: @opportunity.contact_name)
  end

  def opportunity_related_account
    return nil unless @opportunity&.account_name.present?
    @opportunity_related_account ||= Account.find_by(name: @opportunity.account_name)
  end

  def note_association_badge(notable)
    return nil unless notable

    case notable
    when Contact
      link_to contact_path(notable),
              class: "inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-blue-100 text-blue-800 hover:bg-blue-200" do
        content_tag(:svg, class: "mr-1 h-3 w-3", fill: "currentColor", viewBox: "0 0 20 20") do
          content_tag(:path, nil, d: "M10 9a3 3 0 100-6 3 3 0 000 6zm-7 9a7 7 0 1114 0H3z")
        end + notable.full_name
      end
    when Opportunity
      link_to opportunity_path(notable),
              class: "inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-purple-100 text-purple-800 hover:bg-purple-200" do
        content_tag(:svg, class: "mr-1 h-3 w-3", fill: "currentColor", viewBox: "0 0 20 20") do
          content_tag(:path, nil, d: "M8.433 7.418c.155-.103.346-.196.567-.267v1.698a2.305 2.305 0 01-.567-.267C8.07 8.34 8 8.114 8 8c0-.114.07-.34.433-.582zM11 12.849v-1.698c.22.071.412.164.567.267.364.243.433.468.433.582 0 .114-.07.34-.433.582a2.305 2.305 0 01-.567.267z") +
          content_tag(:path, nil, "fill-rule": "evenodd", d: "M10 18a8 8 0 100-16 8 8 0 000 16zm1-13a1 1 0 10-2 0v.092a4.535 4.535 0 00-1.676.662C6.602 6.234 6 7.009 6 8c0 .99.602 1.765 1.324 2.246.48.32 1.054.545 1.676.662v1.941c-.391-.127-.68-.317-.843-.504a1 1 0 10-1.51 1.31c.562.649 1.413 1.076 2.353 1.253V15a1 1 0 102 0v-.092a4.535 4.535 0 001.676-.662C13.398 13.766 14 12.991 14 12c0-.99-.602-1.765-1.324-2.246A4.535 4.535 0 0011 9.092V7.151c.391.127.68.317.843.504a1 1 0 101.511-1.31c-.563-.649-1.413-1.076-2.354-1.253V5z", "clip-rule": "evenodd")
        end + notable.opportunity_name
      end
    when Account
      link_to account_path(notable),
              class: "inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-green-100 text-green-800 hover:bg-green-200" do
        content_tag(:svg, class: "mr-1 h-3 w-3", fill: "currentColor", viewBox: "0 0 20 20") do
          content_tag(:path, nil, "fill-rule": "evenodd", d: "M4 4a2 2 0 012-2h8a2 2 0 012 2v12a1 1 0 110 2h-3a1 1 0 01-1-1v-2a1 1 0 00-1-1H9a1 1 0 00-1 1v2a1 1 0 01-1 1H4a1 1 0 110-2V4zm3 1h2v2H7V5zm2 4H7v2h2V9zm2-4h2v2h-2V5zm2 4h-2v2h2V9z", "clip-rule": "evenodd")
        end + notable.name
      end
    when Lead
      link_to lead_path(notable),
              class: "inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-yellow-100 text-yellow-800 hover:bg-yellow-200" do
        content_tag(:svg, class: "mr-1 h-3 w-3", fill: "currentColor", viewBox: "0 0 20 20") do
          content_tag(:path, nil, d: "M10 12a2 2 0 100-4 2 2 0 000 4z") +
          content_tag(:path, nil, "fill-rule": "evenodd", d: "M.458 10C1.732 5.943 5.522 3 10 3s8.268 2.943 9.542 7c-1.274 4.057-5.064 7-9.542 7S1.732 14.057.458 10zM14 10a4 4 0 11-8 0 4 4 0 018 0z", "clip-rule": "evenodd")
        end + notable.full_name
      end
    end
  end

  def sortable_header(column, title, current_sort: nil, current_direction: nil, path: nil)
    # Determine the direction for the next click
    direction = if column == current_sort
      current_direction == "asc" ? "desc" : "asc"
    else
      "asc"
    end

    # Build the link with current filter parameters preserved
    link_params = request.query_parameters.merge(sort: column, direction: direction)

    # Use the provided path or infer from controller
    link_path = path || url_for(controller: controller_name, action: "index")

    # Create the link
    link_to "#{link_path}?#{link_params.to_query}", class: "group inline-flex items-center hover:text-gray-900" do
      content = title.html_safe

      # Add sort indicator
      if column == current_sort
        icon_class = current_direction == "asc" ? "rotate-180" : ""
        content += content_tag(:span, class: "ml-2 flex-none rounded text-gray-400 group-hover:visible group-focus:visible #{icon_class}") do
          # Down arrow (rotated for asc)
          raw('<svg class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
            <path fill-rule="evenodd" d="M5.23 7.21a.75.75 0 011.06.02L10 11.168l3.71-3.938a.75.75 0 111.08 1.04l-4.25 4.5a.75.75 0 01-1.08 0l-4.25-4.5a.75.75 0 01.02-1.06z" clip-rule="evenodd" />
          </svg>')
        end
      else
        # Show faded arrow on hover for non-active columns
        content += content_tag(:span, class: "ml-2 flex-none rounded text-gray-400 invisible group-hover:visible group-focus:visible") do
          raw('<svg class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
            <path fill-rule="evenodd" d="M5.23 7.21a.75.75 0 011.06.02L10 11.168l3.71-3.938a.75.75 0 111.08 1.04l-4.25 4.5a.75.75 0 01-1.08 0l-4.25-4.5a.75.75 0 01.02-1.06z" clip-rule="evenodd" />
          </svg>')
        end
      end

      content
    end
  end
end
