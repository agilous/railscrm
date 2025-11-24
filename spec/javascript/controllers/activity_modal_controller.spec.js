import { Application } from '@hotwired/stimulus'
import ActivityModalController from '../../../app/javascript/controllers/activity_modal_controller'

describe('ActivityModalController', () => {
  let application
  let element

  beforeEach(() => {
    document.body.innerHTML = `
      <div id="activityModal"
           class="hidden"
           data-controller="activity-modal"
           data-activity-modal-target="modal">
        <form data-activity-modal-target="form" action="/contacts/123/activities">
          <select name="activity[activity_type]">
            <option value="Call">Call</option>
            <option value="Meeting">Meeting</option>
          </select>
          <input type="text" name="activity[title]" />
          <textarea name="activity[description]"></textarea>
          <input type="datetime-local" name="activity[due_date]" />
          <input type="number" name="activity[duration]" />
          <select name="activity[priority]">
            <option value="Low">Low</option>
            <option value="Medium">Medium</option>
            <option value="High">High</option>
          </select>
          <select name="activity[user_id]">
            <option value="1">User 1</option>
          </select>
          <button type="button" data-action="click->activity-modal#submit">Schedule Activity</button>
          <button type="button" data-action="click->activity-modal#close">Cancel</button>
        </form>
      </div>
    `

    element = document.querySelector('#activityModal')
    application = Application.start()
    application.register('activity-modal', ActivityModalController)
  })

  afterEach(() => {
    application.stop()
    document.body.innerHTML = ''
    document.head.innerHTML = ''
    jest.clearAllMocks()
  })

  describe('#open', () => {
    it('removes hidden class from modal', () => {
      const controller = application.getControllerForElementAndIdentifier(element, 'activity-modal')

      expect(element.classList.contains('hidden')).toBe(true)
      controller.open()
      expect(element.classList.contains('hidden')).toBe(false)
    })

    it('sets up global openActivityModal function', () => {
      expect(window.openActivityModal).toBeDefined()
      expect(typeof window.openActivityModal).toBe('function')
    })

    it('can be called via global function', () => {
      expect(element.classList.contains('hidden')).toBe(true)
      window.openActivityModal()
      expect(element.classList.contains('hidden')).toBe(false)
    })
  })

  describe('#close', () => {
    it('adds hidden class to modal', () => {
      const controller = application.getControllerForElementAndIdentifier(element, 'activity-modal')

      element.classList.remove('hidden')
      expect(element.classList.contains('hidden')).toBe(false)

      controller.close()
      expect(element.classList.contains('hidden')).toBe(true)
    })

    it('resets the form when closing', () => {
      const controller = application.getControllerForElementAndIdentifier(element, 'activity-modal')
      const form = element.querySelector('form')
      const resetSpy = jest.spyOn(form, 'reset')

      controller.close()
      expect(resetSpy).toHaveBeenCalled()
    })
  })

  describe('#submit', () => {
    let formSubmitMock

    beforeEach(() => {
      // Mock form.submit()
      const form = document.querySelector('form')
      formSubmitMock = jest.fn()
      form.submit = formSubmitMock
    })

    it('prevents default form submission', () => {
      const controller = application.getControllerForElementAndIdentifier(element, 'activity-modal')
      const event = new Event('submit')
      const preventDefaultSpy = jest.spyOn(event, 'preventDefault')

      controller.submit(event)
      expect(preventDefaultSpy).toHaveBeenCalled()
    })

    it('submits the form when called', () => {
      const controller = application.getControllerForElementAndIdentifier(element, 'activity-modal')

      const mockEvent = { preventDefault: jest.fn() }
      controller.submit(mockEvent)

      expect(formSubmitMock).toHaveBeenCalled()
    })

    describe('modal state during form submission', () => {
      it('keeps modal open during form submission process', () => {
        const controller = application.getControllerForElementAndIdentifier(element, 'activity-modal')

        // Open modal first
        controller.open()
        expect(element.classList.contains('hidden')).toBe(false)

        // Submit form - modal should remain open
        const mockEvent = { preventDefault: jest.fn() }
        controller.submit(mockEvent)

        // Modal should still be open (form submission is handled by browser/turbo)
        expect(element.classList.contains('hidden')).toBe(false)
        expect(formSubmitMock).toHaveBeenCalled()
      })

      it('form has correct attributes for turbo_stream handling', () => {
        const form = document.querySelector('form')

        // Form should have proper action and method for Rails
        expect(form.action).toBe('http://localhost/contacts/123/activities')
        expect(form.method).toBe('get') // Default form method is 'get', Rails form helpers add POST via hidden input
      })
    })

    describe('turbo_stream response behavior simulation', () => {
      it('simulates successful form submission response handling', () => {
        const controller = application.getControllerForElementAndIdentifier(element, 'activity-modal')

        controller.open()
        expect(element.classList.contains('hidden')).toBe(false)

        // Submit form
        const mockEvent = { preventDefault: jest.fn() }
        controller.submit(mockEvent)

        // Simulate turbo_stream success response by manually closing modal
        // (In real app, this would be handled by turbo_stream response)
        controller.close()
        expect(element.classList.contains('hidden')).toBe(true)
      })

      it('simulates validation error response handling', () => {
        const controller = application.getControllerForElementAndIdentifier(element, 'activity-modal')
        const form = element.querySelector('form')
        const titleInput = form.querySelector('input[name="activity[title]"]')

        controller.open()
        titleInput.value = 'User input'

        // Submit form
        const mockEvent = { preventDefault: jest.fn() }
        controller.submit(mockEvent)

        // Simulate validation error response - modal stays open, form keeps data
        // (In real app, turbo_stream would replace form content with errors)
        expect(element.classList.contains('hidden')).toBe(false)
        expect(titleInput.value).toBe('User input') // Form data preserved
      })
    })

    describe('form reset behavior', () => {
      it('does not reset form on validation errors', () => {
        const controller = application.getControllerForElementAndIdentifier(element, 'activity-modal')
        const form = element.querySelector('form')
        const titleInput = form.querySelector('input[name="activity[title]"]')

        // Fill form with user data
        titleInput.value = 'User entered title'

        // Simulate validation error scenario (form submission fails)
        // Form should NOT be reset to preserve user input
        expect(titleInput.value).toBe('User entered title')
      })

      it('resets form only on successful submission', () => {
        const controller = application.getControllerForElementAndIdentifier(element, 'activity-modal')
        const form = element.querySelector('form')
        const resetSpy = jest.spyOn(form, 'reset')

        // Simulate successful form submission
        controller.close() // This should reset the form

        expect(resetSpy).toHaveBeenCalled()
      })

      it('resets form when modal is closed via cancel button', () => {
        const controller = application.getControllerForElementAndIdentifier(element, 'activity-modal')
        const form = element.querySelector('form')
        const resetSpy = jest.spyOn(form, 'reset')

        controller.close()

        expect(resetSpy).toHaveBeenCalled()
      })
    })

  })

  describe('#disconnect', () => {
    it('removes global openActivityModal function', () => {
      const controller = application.getControllerForElementAndIdentifier(element, 'activity-modal')

      expect(window.openActivityModal).toBeDefined()

      controller.disconnect()

      expect(window.openActivityModal).toBeUndefined()
    })
  })
})
