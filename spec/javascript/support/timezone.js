// Set consistent timezone for Jest tests
// This ensures tests run with the same timezone locally and in CI

// Default timezone for tests (can be overridden)
const DEFAULT_TIMEZONE = 'America/New_York'
process.env.TZ = process.env.TZ || DEFAULT_TIMEZONE

// Store the original Intl.DateTimeFormat
const originalDateTimeFormat = Intl.DateTimeFormat

// Helper function to mock timezone for specific tests
global.mockTimezone = function(timezone) {
  process.env.TZ = timezone

  // Create a mock DateTimeFormat function
  const MockDateTimeFormat = function(...args) {
    const instance = new originalDateTimeFormat(...args)
    const originalResolvedOptions = instance.resolvedOptions.bind(instance)

    instance.resolvedOptions = function() {
      const options = originalResolvedOptions()
      options.timeZone = timezone
      return options
    }

    return instance
  }

  // Preserve static methods and prototype
  Object.setPrototypeOf(MockDateTimeFormat, originalDateTimeFormat)
  MockDateTimeFormat.supportedLocalesOf = originalDateTimeFormat.supportedLocalesOf

  global.Intl.DateTimeFormat = MockDateTimeFormat
}

// Helper function to restore original timezone behavior
global.restoreTimezone = function() {
  process.env.TZ = DEFAULT_TIMEZONE
  global.Intl.DateTimeFormat = originalDateTimeFormat
}

// Set up default timezone mock
global.mockTimezone(process.env.TZ || DEFAULT_TIMEZONE)