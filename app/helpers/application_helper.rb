module ApplicationHelper
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
    link_path = path || url_for(controller: controller_name, action: 'index')

    # Create the link
    link_to link_path + "?" + link_params.to_query, class: "group inline-flex items-center hover:text-gray-900" do
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
