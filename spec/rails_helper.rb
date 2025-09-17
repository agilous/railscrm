# This file is copied to spec/ when you run 'rails generate rspec:install'
require 'spec_helper'
ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
# Prevent database truncation if the environment is production
abort("The Rails environment is running in production mode!") if Rails.env.production?
# Uncomment the line below in case you have `--require rails_helper` in the `.rspec` file
# that will avoid rails generators crashing because migrations haven't been run yet
# return unless Rails.env.test?
require 'rspec/rails'
require 'capybara/rails'
require 'capybara/rspec'
# Add additional requires below this line. Rails is not loaded until this point!

# Requires supporting ruby files with custom matchers and macros, etc, in
# spec/support/ and its subdirectories. Files matching `spec/**/*_spec.rb` are
# run as spec files by default. This means that files in spec/support that end
# in _spec.rb will both be required and run as specs, causing the specs to be
# run twice. It is recommended that you do not name files matching this glob to
# end with _spec.rb. You can configure this pattern with the --pattern
# option on the command line or in ~/.rspec, .rspec or `.rspec-local`.
#
# The following line is provided for convenience purposes. It has the downside
# of increasing the boot-up time by auto-requiring all files in the support
# directory. Alternatively, in the individual `*_spec.rb` files, manually
# require only the support files necessary.
#
Rails.root.glob('spec/support/**/*.rb').sort_by(&:to_s).each { |f| require f }

# Force eager loading of routes for Devise compatibility with Rails 8
Rails.application.routes.default_url_options[:host] = 'test.example.com'

# Ensures that the test database schema matches the current schema file.
# If there are pending migrations it will invoke `db:test:prepare` to
# recreate the test database by loading the schema.
# If you are not using ActiveRecord, you can remove these lines.
begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  abort e.to_s.strip
end
RSpec.configure do |config|
  # FactoryBot integration
  config.include FactoryBot::Syntax::Methods

  # Devise test helpers
  config.include Devise::Test::IntegrationHelpers, type: :request
  config.include Devise::Test::ControllerHelpers, type: :controller
  config.include Devise::Test::IntegrationHelpers, type: :system

  # Include route helpers for all test types
  config.include Rails.application.routes.url_helpers

  # Configure host for URL helpers in tests
  config.before(:each, type: :request) do
    host! 'www.example.com'
  end

  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_paths = [
    Rails.root.join('spec/fixtures')
  ]

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = true

  # You can uncomment this line to turn off ActiveRecord support entirely.
  # config.use_active_record = false

  # RSpec Rails uses metadata to mix in different behaviours to your tests,
  # for example enabling you to call `get` and `post` in request specs. e.g.:
  #
  #     RSpec.describe UsersController, type: :request do
  #       # ...
  #     end
  #
  # The different available types are documented in the features, such as in
  # https://rspec.info/features/8-0/rspec-rails
  #
  # You can also this infer these behaviours automatically by location, e.g.
  # /spec/models would pull in the same behaviour as `type: :model` but this
  # behaviour is considered legacy and will be removed in a future version.
  #
  # To enable this behaviour uncomment the line below.
  config.infer_spec_type_from_file_location!

  # Filter lines from Rails gems in backtraces.
  config.filter_rails_from_backtrace!
  # arbitrary gems may also be filtered via:
  # config.filter_gems_from_backtrace("gem name")
end

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end

# Capybara configuration with Selenium Chrome (cross-platform compatible)
require 'selenium-webdriver'

# Helper method to find Chrome executable across platforms
def find_chrome_executable
  chrome_paths = [
    '/usr/bin/chromium-browser',         # Linux (Chromium) - prioritize reliable option
    '/snap/bin/chromium',                # Linux (Snap)
    '/opt/google/chrome/google-chrome',  # Linux (Google Chrome direct path)
    '/usr/bin/google-chrome-stable',     # Linux (Google Chrome stable)
    '/usr/bin/google-chrome',            # Linux (Google Chrome symlink)
    '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome', # macOS
    '/Applications/Chromium.app/Contents/MacOS/Chromium'            # macOS Chromium
  ]

  chrome_paths.find { |path| File.executable?(path) }
end

# Configure Selenium Chrome driver with cross-platform support
Capybara.register_driver :selenium_chrome_headless do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_argument('--headless=new')
  options.add_argument('--no-sandbox')
  options.add_argument('--disable-dev-shm-usage')
  options.add_argument('--disable-gpu')
  options.add_argument('--remote-debugging-port=9222')

  # Set Chrome binary path if found
  chrome_path = find_chrome_executable
  if chrome_path
    options.binary = chrome_path
  end

  # OS-specific configuration to handle driver compatibility
  case RUBY_PLATFORM
  when /darwin/
    # macOS: Use the compatible driver from Selenium's cache
    # Check for cached compatible driver
    cached_driver_path = Dir.glob(File.expand_path("~/.cache/selenium/chromedriver/mac-*/131.*/chromedriver")).first

    if cached_driver_path && File.executable?(cached_driver_path)
      # Use the cached compatible driver
      service = Selenium::WebDriver::Chrome::Service.new(path: cached_driver_path)
      Capybara::Selenium::Driver.new(app,
        browser: :chrome,
        options: options,
        service: service
      )
    else
      # Fallback: Let Selenium download the correct driver
      # by temporarily removing incompatible drivers from PATH
      original_path = ENV['PATH']
      begin
        ENV['PATH'] = original_path.split(':').reject { |p|
          p.include?('/opt/homebrew') || p.include?('/usr/local/bin')
        }.join(':')

        driver = Capybara::Selenium::Driver.new(app,
          browser: :chrome,
          options: options
        )
      ensure
        ENV['PATH'] = original_path
      end
      driver
    end
  when /linux/
    # Linux: Standard configuration works well
    Capybara::Selenium::Driver.new(app,
      browser: :chrome,
      options: options
    )
  else
    # Default fallback
    Capybara::Selenium::Driver.new(app,
      browser: :chrome,
      options: options
    )
  end
end

# For JavaScript-enabled tests, use Selenium Chrome
Capybara.javascript_driver = :selenium_chrome_headless
# For non-JS tests, use the faster rack_test
Capybara.default_driver = :rack_test

# Configure Capybara settings
Capybara.default_max_wait_time = 5
Capybara.server = :puma, { Silent: true }
