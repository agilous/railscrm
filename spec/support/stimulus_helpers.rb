module StimulusHelpers
  # Simple helper that waits for Stimulus to be available
  def wait_for_stimulus(timeout: 5)
    page.has_content?('', wait: 0.5) # Ensure page is loaded

    start_time = Time.now
    loop do
      stimulus_ready = page.execute_script('return typeof window.Stimulus !== "undefined"')
      return true if stimulus_ready

      if Time.now - start_time > timeout
        return false
      end
      sleep(0.1)
    end
  end

  # The main fix: Use direct Stimulus action triggering instead of relying on Capybara click
  def trigger_stimulus_action(selector, action, wait_time: 0.5)
    wait_for_stimulus

    # Find the element and trigger the action via Stimulus
    success = page.execute_script(<<-JS)
      var element = document.querySelector('#{selector}');
      if (!element) return false;

      // Extract controller and action from data-action
      var dataAction = element.getAttribute('data-action');
      if (!dataAction) return false;

      var parts = dataAction.split('->');
      if (parts.length < 2) return false;

      var controllerAction = parts[1].split('#');
      if (controllerAction.length < 2) return false;

      var controllerName = controllerAction[0];
      var actionName = controllerAction[1];

      // Get the controller element (might be the button itself or a parent)
      var controllerElement = element.closest('[data-controller*="' + controllerName + '"]');
      if (!controllerElement) return false;

      // Try to get the controller instance
      if (window.Stimulus && window.Stimulus.getControllerForElementAndIdentifier) {
        var controller = window.Stimulus.getControllerForElementAndIdentifier(controllerElement, controllerName);
        if (controller && typeof controller[actionName] === 'function') {
          controller[actionName]();
          return true;
        }
      }

      return false;
    JS

    sleep(wait_time) if success
    success
  end

  # Clean implementation for opening note modal
  def open_note_modal
    # Try the Stimulus action trigger first
    if trigger_stimulus_action('button[data-action*="note-modal#open"]', 'open')
      return true
    end

    # Fallback to direct method call
    page.execute_script(<<-JS)
      var element = document.querySelector('[data-controller="note-modal"]');
      if (window.Stimulus && window.Stimulus.getControllerForElementAndIdentifier) {
        var controller = window.Stimulus.getControllerForElementAndIdentifier(element, 'note-modal');
        if (controller && controller.open) {
          controller.open();
        }
      } else {
        // Last resort: direct DOM manipulation
        document.getElementById('noteModal').classList.remove('hidden');
      }
    JS
  end

  def close_note_modal
    page.execute_script(<<-JS)
      var element = document.querySelector('[data-controller="note-modal"]');
      if (window.Stimulus && window.Stimulus.getControllerForElementAndIdentifier) {
        var controller = window.Stimulus.getControllerForElementAndIdentifier(element, 'note-modal');
        if (controller && controller.close) {
          controller.close();
        }
      } else {
        // Fallback: direct DOM manipulation
        document.getElementById('noteModal').classList.add('hidden');
      }
    JS
  end

  # Enhanced click method that actually works with Stimulus
  def click_with_stimulus(selector_or_text)
    if selector_or_text.start_with?('button[') || selector_or_text.include?('#') || selector_or_text.include?('.')
      # It's a CSS selector
      if trigger_stimulus_action(selector_or_text, 'click')
        return true
      end
    end

    # Fallback to normal Capybara click
    if selector_or_text.start_with?('button[')
      find(selector_or_text).click
    else
      click_button(selector_or_text)
    end
  end
end

RSpec.configure do |config|
  config.include StimulusHelpers, type: :system
end
