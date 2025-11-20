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
    let fetchMock

    beforeEach(() => {
      // Mock fetch
      fetchMock = jest.fn(() =>
        Promise.resolve({
          ok: true,
          json: () => Promise.resolve({ success: true })
        })
      )
      global.fetch = fetchMock

      // Mock location.reload
      delete window.location
      window.location = { reload: jest.fn() }

      // Add CSRF token meta tag
      const meta = document.createElement('meta')
      meta.setAttribute('name', 'csrf-token')
      meta.setAttribute('content', 'test-token')
      document.head.appendChild(meta)
    })

    it('prevents default form submission', async () => {
      const controller = application.getControllerForElementAndIdentifier(element, 'activity-modal')
      const event = new Event('submit')
      const preventDefaultSpy = jest.spyOn(event, 'preventDefault')

      await controller.submit(event)
      expect(preventDefaultSpy).toHaveBeenCalled()
    })

    it('sends POST request with form data to correct URL', async () => {
      const controller = application.getControllerForElementAndIdentifier(element, 'activity-modal')
      const form = element.querySelector('form')

      form.querySelector('[name="activity[title]"]').value = 'Follow up call'
      form.querySelector('[name="activity[activity_type]"]').value = 'Call'

      const mockEvent = { preventDefault: jest.fn() }
      await controller.submit(mockEvent)

      expect(fetchMock).toHaveBeenCalledWith(expect.stringContaining('/contacts/123/activities'), expect.objectContaining({
        method: 'POST',
        headers: expect.objectContaining({
          'X-CSRF-Token': 'test-token',
          'Accept': 'application/json'
        }),
        body: expect.any(FormData)
      }))
    })

    it('includes activity data in form submission', async () => {
      const controller = application.getControllerForElementAndIdentifier(element, 'activity-modal')
      const form = element.querySelector('form')

      form.querySelector('[name="activity[title]"]').value = 'Follow up call'
      form.querySelector('[name="activity[activity_type]"]').value = 'Call'
      form.querySelector('[name="activity[description]"]').value = 'Discuss project details'
      form.querySelector('[name="activity[duration]"]').value = '30'
      form.querySelector('[name="activity[priority]"]').value = 'High'

      const mockEvent = { preventDefault: jest.fn() }
      await controller.submit(mockEvent)

      const formData = fetchMock.mock.calls[0][1].body
      expect(formData.get('activity[title]')).toBe('Follow up call')
      expect(formData.get('activity[activity_type]')).toBe('Call')
      expect(formData.get('activity[description]')).toBe('Discuss project details')
      expect(formData.get('activity[duration]')).toBe('30')
      expect(formData.get('activity[priority]')).toBe('High')
    })

    it('reloads page on successful submission', async () => {
      const controller = application.getControllerForElementAndIdentifier(element, 'activity-modal')

      const mockEvent = { preventDefault: jest.fn() }
      await controller.submit(mockEvent)

      expect(window.location.reload).toHaveBeenCalled()
    })

    it('shows alert on failed submission', async () => {
      fetchMock.mockResolvedValueOnce({
        ok: false,
        status: 422,
        text: () => Promise.resolve('Validation error')
      })

      const alertSpy = jest.spyOn(window, 'alert').mockImplementation(() => {})
      const controller = application.getControllerForElementAndIdentifier(element, 'activity-modal')

      const mockEvent = { preventDefault: jest.fn() }
      await controller.submit(mockEvent)

      expect(alertSpy).toHaveBeenCalledWith('Failed to save activity: 422')
      expect(window.location.reload).not.toHaveBeenCalled()
    })

    it('handles network errors', async () => {
      fetchMock.mockRejectedValueOnce(new Error('Network error'))

      const alertSpy = jest.spyOn(window, 'alert').mockImplementation(() => {})
      const controller = application.getControllerForElementAndIdentifier(element, 'activity-modal')

      const mockEvent = { preventDefault: jest.fn() }
      await controller.submit(mockEvent)

      expect(alertSpy).toHaveBeenCalledWith('An error occurred: Network error')
      expect(window.location.reload).not.toHaveBeenCalled()
    })

    it('handles missing CSRF token', async () => {
      // Remove CSRF token
      document.querySelector('meta[name="csrf-token"]').remove()

      // Ensure no authenticity token input exists either
      const authTokens = document.querySelectorAll('input[name="authenticity_token"]')
      authTokens.forEach(token => token.remove())

      const alertSpy = jest.spyOn(window, 'alert').mockImplementation(() => {})
      const controller = application.getControllerForElementAndIdentifier(element, 'activity-modal')

      const mockEvent = { preventDefault: jest.fn() }
      await controller.submit(mockEvent)

      expect(alertSpy).toHaveBeenCalledWith('An error occurred: CSRF token not found')
      expect(fetchMock).not.toHaveBeenCalled()
    })

    it('tries authenticity token as fallback for CSRF', async () => {
      // Remove CSRF meta tag
      document.querySelector('meta[name="csrf-token"]').remove()

      // Add authenticity token input
      const input = document.createElement('input')
      input.setAttribute('name', 'authenticity_token')
      input.setAttribute('value', 'fallback-token')
      document.body.appendChild(input)

      const controller = application.getControllerForElementAndIdentifier(element, 'activity-modal')

      const mockEvent = { preventDefault: jest.fn() }
      await controller.submit(mockEvent)

      // Verify fetch was called with the fallback token
      expect(fetchMock).toHaveBeenCalled()
      const callArgs = fetchMock.mock.calls[0]
      expect(callArgs[0]).toContain('/contacts/123/activities')
      expect(callArgs[1].headers['X-CSRF-Token']).toBe('fallback-token')
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
