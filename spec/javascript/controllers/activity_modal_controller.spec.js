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
