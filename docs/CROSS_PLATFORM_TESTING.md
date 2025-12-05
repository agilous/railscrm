# Cross-Platform Testing Configuration

This document explains the work done to make the test environment configuration portable between macOS and Linux systems, particularly for system tests using Chrome WebDriver with Selenium.

## Overview

The Wendell CRM application needed cross-platform compatibility for system tests that use Chrome WebDriver. The main challenge was handling different Chrome executable locations and ChromeDriver versions across macOS and Linux systems.

## Problem

- **macOS**: Chrome is typically installed at `/Applications/Google Chrome.app/Contents/MacOS/Google Chrome`
- **Linux**: Chrome/Chromium can be in various locations like `/usr/bin/google-chrome`, `/usr/bin/chromium-browser`, etc.
- **ChromeDriver versions**: Must match the installed Chrome version, but automated tools often download incompatible versions

## Solution Implemented

### File: `spec/rails_helper.rb`

The cross-platform configuration was implemented in the RSpec configuration:

```ruby
RSpec.configure do |config|
  # ... other configuration ...

  config.before(:each, type: :system) do
    if ENV['CI']
      # CI environment - let Selenium handle driver management
      driven_by :selenium, using: :headless_chrome, screen_size: [1400, 1400]
    else
      # Local development - OS-specific configuration
      if RUBY_PLATFORM.include?('darwin') # macOS
        # Try to use cached compatible ChromeDriver first
        cached_driver = Dir.glob(File.expand_path("~/.cache/selenium/chromedriver/mac-*/131.*/chromedriver")).first
        
        if cached_driver && File.executable?(cached_driver)
          # Use the cached compatible driver
          Selenium::WebDriver::Chrome::Service.driver_path = cached_driver
        else
          # Force Selenium to download correct ChromeDriver version
          ENV['SE_MANAGER_PATH'] = '/tmp/selenium-manager'
        end

        driven_by :selenium, using: :headless_chrome, screen_size: [1400, 1400], options: {
          browser: :chrome,
          capabilities: [Selenium::WebDriver::Chrome::Options.new(args: %w[
            --headless
            --no-sandbox
            --disable-dev-shm-usage
            --disable-gpu
            --remote-debugging-port=9222
            --window-size=1400,1400
          ])]
        }
      else # Linux
        # Linux-specific Chrome/Chromium detection and configuration
        chrome_binary = [
          '/usr/bin/google-chrome',
          '/usr/bin/google-chrome-stable',
          '/usr/bin/chromium-browser',
          '/usr/bin/chromium',
          '/snap/bin/chromium'
        ].find { |path| File.executable?(path) }

        raise "Chrome/Chromium not found on Linux system" unless chrome_binary

        # Try to use cached compatible ChromeDriver
        cached_driver = Dir.glob(File.expand_path("~/.cache/selenium/chromedriver/linux*/131.*/chromedriver")).first
        
        if cached_driver && File.executable?(cached_driver)
          Selenium::WebDriver::Chrome::Service.driver_path = cached_driver
        else
          ENV['SE_MANAGER_PATH'] = '/tmp/selenium-manager'
        end

        driven_by :selenium, using: :headless_chrome, screen_size: [1400, 1400], options: {
          browser: :chrome,
          capabilities: [Selenium::WebDriver::Chrome::Options.new(
            binary: chrome_binary,
            args: %w[
              --headless
              --no-sandbox
              --disable-dev-shm-usage
              --disable-gpu
              --remote-debugging-port=9222
              --window-size=1400,1400
              --disable-background-timer-throttling
              --disable-backgrounding-occluded-windows
              --disable-renderer-backgrounding
            ]
          )]
        }
      end
    end
  end
end
```

## Key Components

### 1. Platform Detection

```ruby
if RUBY_PLATFORM.include?('darwin') # macOS
  # macOS-specific configuration
else # Linux  
  # Linux-specific configuration
end
```

Uses Ruby's `RUBY_PLATFORM` constant to detect the operating system.

### 2. Chrome Binary Detection (Linux)

```ruby
chrome_binary = [
  '/usr/bin/google-chrome',
  '/usr/bin/google-chrome-stable', 
  '/usr/bin/chromium-browser',
  '/usr/bin/chromium',
  '/snap/bin/chromium'
].find { |path| File.executable?(path) }
```

Searches common Chrome/Chromium installation paths on Linux systems.

### 3. ChromeDriver Caching Strategy

```ruby
# Look for cached compatible driver
cached_driver = Dir.glob(File.expand_path("~/.cache/selenium/chromedriver/mac-*/131.*/chromedriver")).first

if cached_driver && File.executable?(cached_driver)
  Selenium::WebDriver::Chrome::Service.driver_path = cached_driver
else
  # Fall back to Selenium Manager
  ENV['SE_MANAGER_PATH'] = '/tmp/selenium-manager'
end
```

- First tries to use a cached ChromeDriver that matches the Chrome version
- Falls back to Selenium Manager if no compatible cached driver is found
- Prevents version mismatch errors

### 4. Chrome Options

Different Chrome options are applied based on the platform:

**macOS Options:**
```ruby
args: %w[
  --headless
  --no-sandbox
  --disable-dev-shm-usage
  --disable-gpu
  --remote-debugging-port=9222
  --window-size=1400,1400
]
```

**Linux Options (additional):**
```ruby
args: %w[
  --headless
  --no-sandbox
  --disable-dev-shm-usage
  --disable-gpu
  --remote-debugging-port=9222
  --window-size=1400,1400
  --disable-background-timer-throttling
  --disable-backgrounding-occluded-windows
  --disable-renderer-backgrounding
]
```

Linux includes additional flags to prevent backgrounding issues in headless mode.

## CI Environment Handling

```ruby
if ENV['CI']
  driven_by :selenium, using: :headless_chrome, screen_size: [1400, 1400]
else
  # Local development configuration
end
```

CI environments use simplified configuration, letting the CI system handle Chrome installation and driver management.

## Usage Instructions

### For macOS Development

1. Install Chrome normally through the App Store or download
2. Run tests - the configuration will automatically:
   - Detect macOS platform
   - Look for cached compatible ChromeDriver
   - Download correct ChromeDriver if needed
   - Use appropriate Chrome options

### For Linux Development

1. Install Chrome or Chromium:
   ```bash
   # Ubuntu/Debian
   sudo apt install google-chrome-stable
   # OR
   sudo apt install chromium-browser
   
   # CentOS/RHEL
   sudo yum install google-chrome-stable
   # OR  
   sudo yum install chromium
   ```

2. Run tests - the configuration will automatically:
   - Detect Linux platform
   - Find Chrome/Chromium binary
   - Look for cached compatible ChromeDriver
   - Download correct ChromeDriver if needed
   - Use appropriate Chrome options for Linux

### Troubleshooting

#### Chrome Version Mismatch
If you see errors like "ChromeDriver version X is incompatible with Chrome version Y":

1. Delete cached drivers:
   ```bash
   rm -rf ~/.cache/selenium/chromedriver/
   ```

2. Run tests again - Selenium Manager will download the correct version

#### Chrome Not Found (Linux)
If you get "Chrome/Chromium not found on Linux system":

1. Install Chrome or Chromium (see Linux installation instructions above)
2. If installed in a non-standard location, add the path to the `chrome_binary` array in `spec/rails_helper.rb`

#### Permission Issues
If ChromeDriver isn't executable:

```bash
chmod +x ~/.cache/selenium/chromedriver/*/chromedriver
```

## Testing the Configuration

Run the system tests to verify cross-platform compatibility:

```bash
# Run all system tests
bundle exec rspec spec/system/

# Run a specific system test
bundle exec rspec spec/system/contacts_crud_spec.rb

# Run CI pipeline (includes system tests)
./bin/ci
```

## Maintenance Notes

- **ChromeDriver caching**: The configuration looks for specific Chrome version patterns (like `131.*`). Update these patterns when Chrome major versions change.
- **New Chrome locations**: If Chrome gets installed in new locations on Linux, add them to the `chrome_binary` array.
- **Browser options**: The Chrome options may need updates for newer Chrome versions or different testing needs.

## Related Files

- `spec/rails_helper.rb` - Main cross-platform configuration
- `spec/system/contacts_crud_spec.rb` - System tests that use this configuration
- `.github/workflows/` - CI configuration (if applicable)

## Benefits

1. **No manual configuration** required when switching between macOS and Linux
2. **Automatic ChromeDriver management** prevents version mismatch issues  
3. **Fallback strategies** ensure tests run even if optimal setup isn't available
4. **CI compatibility** with simplified configuration for automated environments
5. **Developer-friendly** - works out of the box on both platforms

This configuration ensures that system tests run reliably across different development environments without requiring manual setup or platform-specific scripts.