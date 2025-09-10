# Claude Code Testing Guidelines

## Project Context
- **Framework**: Ruby on Rails application
- **JavaScript**: Minimal, primarily Stimulus controllers when needed
- **Testing Stack**: RSpec + Cucumber feature specs + FactoryBot + Page Objects
- **Mocking**: RSpec mocking framework exclusively
- **Fixtures**: Only for test files (uploads, data extraction)
- **Company**: Launch Scout project with business development and technical considerations

## Testing Philosophy & Development Practices

### Test Driven Development (TDD)
We are committed to **Test Driven Development** and follow its core tenets:

**Red-Green-Refactor Cycle:**
1. **Red**: Write a failing test that describes the desired functionality
2. **Green**: Write the minimal code necessary to make the test pass
3. **Refactor**: Improve the code while keeping tests green

**TDD Principles We Follow:**
- **Tests drive the design** - Let tests guide your API and class structure
- **Write only enough code** to make the test pass
- **Refactor with confidence** - Tests provide safety net for improvements
- **Fast feedback loops** - Run tests frequently during development

### Test First Development
For **all new functionality**, we practice **Test First Development**:

```ruby
# Example TDD workflow for a new feature
# 1. RED: Write failing test first
RSpec.describe OrderCalculator do
  describe '#calculate_tax' do
    it 'calculates tax based on order total and tax rate' do
      calculator = described_class.new(tax_rate: 0.08)
      result = calculator.calculate_tax(order_total: 100.00)

      expect(result).to eq(8.00)
    end
  end
end

# 2. GREEN: Write minimal implementation
class OrderCalculator
  def initialize(tax_rate:)
    @tax_rate = tax_rate
  end

  def calculate_tax(order_total:)
    order_total * @tax_rate
  end
end

# 3. REFACTOR: Improve while keeping tests green
class OrderCalculator
  include ActiveModel::Validations

  validates :tax_rate, presence: true, numericality: { greater_than: 0 }

  def initialize(tax_rate:)
    @tax_rate = tax_rate
    validate!
  end

  def calculate_tax(order_total:)
    Money.new((order_total * @tax_rate * 100).round)
  end
end
```

### Testing Requirements

**All code changes must be accompanied by appropriate tests.** We follow these testing practices:

#### Testing Strategy by Layer
- **Request specs are preferred over browser/feature tests** for API and controller testing
- **Write unit tests** for models and service objects
- **Use factories (FactoryBot) instead of fixtures** for test data (except file fixtures)
- **Follow the AAA pattern**: Arrange, Act, Assert
- **Test both happy path and edge cases**
- **Maintain good test coverage but focus on quality over quantity**

#### Detailed Testing Approach

**Request Specs for Controllers/APIs** (Preferred over feature tests for non-UI testing):
```ruby
# spec/requests/users_spec.rb
RSpec.describe 'Users API', type: :request do
  describe 'POST /users' do
    # Arrange
    let(:user_attributes) { attributes_for(:user) }
    let(:email_service) { instance_double('EmailService') }

    before do
      allow(EmailService).to receive(:new).and_return(email_service)
      allow(email_service).to receive(:send_welcome_email)
    end

    context 'with valid parameters' do
      it 'creates user and returns success response' do
        # Act
        post '/users', params: { user: user_attributes }

        # Assert
        expect(response).to have_http_status(:created)
        expect(response.parsed_body['message']).to eq('User created successfully')
        expect(User.count).to eq(1)
        expect(email_service).to have_received(:send_welcome_email)
      end
    end

    context 'with invalid parameters' do
      let(:invalid_attributes) { { email: 'invalid-email' } }

      it 'returns validation errors' do
        # Act
        post '/users', params: { user: invalid_attributes }

        # Assert
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body['errors']).to include('Email is invalid')
        expect(User.count).to eq(0)
      end
    end
  end
end
```

**Unit Tests for Models**:
```ruby
# spec/models/user_spec.rb
RSpec.describe User, type: :model do
  # Arrange - using FactoryBot
  subject(:user) { build(:user, first_name: 'John', last_name: 'Doe') }

  describe 'validations' do
    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_uniqueness_of(:email) }
  end

  describe '#full_name' do
    context 'with both first and last name' do
      it 'returns concatenated name' do
        # Act
        result = user.full_name

        # Assert
        expect(result).to eq('John Doe')
      end
    end

    context 'with missing last name' do
      # Arrange
      before { user.last_name = nil }

      it 'returns only first name' do
        # Act
        result = user.full_name

        # Assert
        expect(result).to eq('John')
      end
    end
  end

  describe '#premium?' do
    context 'when account_type is premium' do
      # Arrange
      before { user.account_type = 'premium' }

      it 'returns true' do
        # Act & Assert
        expect(user).to be_premium
      end
    end

    context 'when account_type is basic' do
      # Arrange
      before { user.account_type = 'basic' }

      it 'returns false' do
        # Act & Assert
        expect(user).not_to be_premium
      end
    end
  end
end
```

**Unit Tests for Service Objects**:
```ruby
# spec/services/user_registration_service_spec.rb
RSpec.describe UserRegistrationService do
  # Arrange
  subject(:service) { described_class.new(email_service: email_service) }

  let(:email_service) { instance_double('EmailService') }
  let(:user_attributes) { attributes_for(:user) }

  before do
    allow(email_service).to receive(:send_welcome_email)
  end

  describe '#register' do
    context 'with valid attributes' do
      it 'creates user and sends welcome email' do
        # Act
        result = service.register(user_attributes)

        # Assert
        expect(result).to be_success
        expect(result.user).to be_persisted
        expect(result.user.email).to eq(user_attributes[:email])
        expect(email_service).to have_received(:send_welcome_email).with(result.user)
      end
    end

    context 'with invalid attributes' do
      # Arrange
      let(:invalid_attributes) { { email: 'invalid' } }

      it 'returns failure with errors' do
        # Act
        result = service.register(invalid_attributes)

        # Assert
        expect(result).to be_failure
        expect(result.errors).to be_present
        expect(email_service).not_to have_received(:send_welcome_email)
      end
    end

    context 'when email service fails' do
      # Arrange
      before do
        allow(email_service).to receive(:send_welcome_email)
          .and_raise(StandardError, 'Email service unavailable')
      end

      it 'still creates user but logs error' do
        # Arrange
        allow(Rails.logger).to receive(:error)

        # Act
        result = service.register(user_attributes)

        # Assert
        expect(result).to be_success
        expect(result.user).to be_persisted
        expect(Rails.logger).to have_received(:error)
          .with(/Failed to send welcome email/)
      end
    end
  end
end
```

**Feature Tests with Cucumber + Page Objects** (For end-to-end user workflows only):
Use Cucumber feature specs for complete user journeys that span multiple pages/interactions:

```gherkin
Feature: Complete User Registration Flow
  As a potential customer
  I want to register and access my dashboard
  So that I can use the platform

  Scenario: Successful registration with email confirmation
    Given I am on the registration page
    When I fill in valid registration details
    And I submit the registration form
    Then I should see a success message
    And I should be redirected to the dashboard
    And I should receive a welcome email
```

### Code Quality & Linting
We maintain high code quality through automated linting:

**Ruby/Rails/RSpec**: **Rubocop** with custom configuration
**JavaScript**: **JSLint** for JavaScript code quality

```ruby
# .rubocop.yml example expectations
# Style/StringLiterals: Enforced
# Layout/LineLength: Max 120 characters
# RSpec/ExampleLength: Max 10 lines per example
# Rails/FilePath: Enforced for consistency

# Claude Code should generate code that passes:
RSpec.describe UserService do
  let(:user_service) { described_class.new }

  describe '#create_user' do
    context 'with valid attributes' do
      it 'creates and returns a new user' do
        user_attributes = attributes_for(:user)

        result = user_service.create_user(user_attributes)

        expect(result).to be_persisted
        expect(result.email).to eq(user_attributes[:email])
      end
    end
  end
end
```

### Development Workflow Expectations

**For Claude Code when generating new functionality:**

1. **Always start with a failing test** (RED)
2. **Write minimal implementation** to pass the test (GREEN)
3. **Suggest refactoring opportunities** while keeping tests green
4. **Follow Rubocop conventions** in generated Ruby code
5. **Use descriptive test names** that explain business value
6. **Generate both unit and integration tests** when appropriate
7. **Follow AAA pattern** in all test examples
8. **Test happy path AND edge cases**

## Core Testing Principles

### ✅ DO Mock/Stub These:

#### External APIs and Services
```ruby
# Payment processing
RSpec.describe OrderProcessor do
  describe '#process_payment' do
    it 'processes payment successfully' do
      payment_service = instance_double('PaymentService')
      allow(payment_service).to receive(:charge)
        .with(100, 'token')
        .and_return(success: true, id: 'ch_123')

      processor = OrderProcessor.new(payment_service)
      result = processor.process_payment(100, 'token')

      expect(result).to be_success
      expect(result.charge_id).to eq('ch_123')
    end
  end
end

# Third-party APIs
RSpec.describe WeatherService do
  describe '#current_weather' do
    it 'fetches weather data from external API' do
      http_client = instance_double('HttpClient')
      allow(http_client).to receive(:get)
        .with('/weather/charlotte')
        .and_return('temperature' => 75, 'condition' => 'sunny')

      service = WeatherService.new(http_client)
      weather = service.current_weather('charlotte')

      expect(weather.temperature).to eq(75)
      expect(weather.condition).to eq('sunny')
    end
  end
end
```

#### File System Operations
```ruby
RSpec.describe ReportGenerator do
  describe '#generate_user_report' do
    it 'generates CSV report without writing to disk' do
      allow(File).to receive(:write).and_return(true)

      user1 = create(:user, name: 'John Doe', email: 'john@example.com')
      user2 = create(:user, name: 'Jane Smith', email: 'jane@example.com')

      generator = ReportGenerator.new
      csv_content = generator.generate_user_report([user1, user2])

      expect(csv_content).to include("John Doe,john@example.com")
      expect(csv_content).to include("Jane Smith,jane@example.com")
    end
  end
end

RSpec.describe PaymentService do
  describe '#log_payment_failure' do
    it 'logs error for failed payment' do
      allow(Rails.logger).to receive(:error)

      service = PaymentService.new
      service.log_payment_failure(order_id: 123)

      expect(Rails.logger).to have_received(:error)
        .with("Payment failed for order #123")
    end
  end
end
```

#### Email and Notifications
```ruby
RSpec.describe UserRegistrationService do
  describe '#register' do
    it 'sends welcome email after user creation' do
      mailer_double = instance_double(ActionMailer::MessageDelivery)
      allow(UserMailer).to receive(:welcome_email).and_return(mailer_double)
      allow(mailer_double).to receive(:deliver_now)

      service = UserRegistrationService.new
      user = service.register(name: "John Doe", email: "john@example.com")

      expect(UserMailer).to have_received(:welcome_email).with(user)
      expect(mailer_double).to have_received(:deliver_now)
    end
  end
end

RSpec.describe NotificationService do
  describe '#notify_new_user' do
    it 'posts message to Slack channel' do
      slack_client = instance_double('SlackClient')
      allow(slack_client).to receive(:post_message)

      service = NotificationService.new(slack_client)
      service.notify_new_user(email: 'john@example.com')

      expect(slack_client).to have_received(:post_message).with(
        channel: '#signups',
        text: "New user registered: john@example.com"
      )
    end
  end
end
```

#### Time-Dependent Code
```ruby
RSpec.describe Subscription do
  describe '#expires_at' do
    it 'sets expiration to 30 days from start date' do
      freeze_time = Time.zone.parse("2025-01-01 10:00:00")

      allow(Time).to receive(:current).and_return(freeze_time)

      subscription = create(:subscription, starts_at: freeze_time)

      expect(subscription.expires_at).to eq(freeze_time + 30.days)
    end
  end
end
```

### ❌ DON'T Mock/Stub These:

#### ActiveRecord Models and Associations
```ruby
# ❌ BAD - Don't do this
RSpec.describe Order do
  describe '#total_with_discount' do
    it 'calculates total with user discount - BAD EXAMPLE' do
      user = instance_double('User', discount_rate: 0.1)
      line_item1 = instance_double('LineItem', price: 50)
      line_item2 = instance_double('LineItem', price: 30)

      order = Order.new(user: user, line_items: [line_item1, line_item2])
      # This tests mocks, not your actual business logic
    end
  end
end

# ✅ GOOD - Use real objects with FactoryBot
RSpec.describe Order do
  describe '#total_with_discount' do
    it 'calculates total with user discount' do
      user = create(:user, discount_rate: 0.1)
      order = create(:order, user: user)
      create(:line_item, order: order, price: 50.00)
      create(:line_item, order: order, price: 30.00)

      expect(order.total_with_discount).to eq(72.00) # 80 * 0.9
    end
  end
end
```

#### Database Queries and Scopes
```ruby
# ❌ BAD - Don't mock ActiveRecord queries
RSpec.describe UserService do
  describe '#active_users' do
    it 'finds active users - BAD EXAMPLE' do
      allow(User).to receive(:where).with(active: true).and_return([user1, user2])
      # This tests that you called .where(), not that your logic works
    end
  end
end

# ✅ GOOD - Use real database records with FactoryBot
RSpec.describe UserService do
  describe '#active_users' do
    it 'returns only active users' do
      active_user = create(:user, :active)
      inactive_user = create(:user, :inactive)

      service = UserService.new
      result = service.active_users

      expect(result).to include(active_user)
      expect(result).not_to include(inactive_user)
    end
  end
end
```

#### Simple Value Objects and POROs
```ruby
# ❌ BAD - Don't mock simple objects
RSpec.describe PriceCalculator do
  describe '#add_tax' do
    it 'adds tax to price - BAD EXAMPLE' do
      price = instance_double('Price', amount: 100)
      # Testing mock behavior, not actual calculation
    end
  end
end

# ✅ GOOD - Use real value objects
RSpec.describe PriceCalculator do
  describe '#add_tax' do
    it 'adds tax to price amount' do
      calculator = PriceCalculator.new(tax_rate: 0.08)
      result = calculator.add_tax(Price.new(100.00))

      expect(result.amount).to eq(108.00)
    end
  end
end
```

## Testing Approach by Layer

### Model Specs (`spec/models/`)
- Use real ActiveRecord objects created with FactoryBot
- Test validations, associations, and business logic methods
- Mock only external service calls from models

```ruby
RSpec.describe User, type: :model do
  describe 'validations' do
    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_uniqueness_of(:email) }
  end

  describe 'associations' do
    it { is_expected.to have_many(:orders) }
  end

  describe '#full_name' do
    it 'concatenates first and last name' do
      user = create(:user, first_name: "John", last_name: "Doe")
      expect(user.full_name).to eq("John Doe")
    end
  end

  describe 'after_create callbacks' do
    it 'sends welcome email' do
      mailer_double = instance_double(ActionMailer::MessageDelivery)
      allow(UserMailer).to receive(:welcome_email).and_return(mailer_double)
      allow(mailer_double).to receive(:deliver_now)

      create(:user)

      expect(UserMailer).to have_received(:welcome_email)
    end
  end
end
```

### Controller Specs (`spec/controllers/` or `spec/requests/`)
- Test HTTP responses and redirects
- Use real models created with FactoryBot
- Mock external service calls
- Focus on request/response cycle

```ruby
RSpec.describe UsersController, type: :controller do
  describe 'POST #create' do
    context 'with valid parameters' do
      it 'creates a new user and redirects' do
        user_params = attributes_for(:user)

        expect {
          post :create, params: { user: user_params }
        }.to change(User, :count).by(1)

        expect(response).to redirect_to(user_path(User.last))
        expect(flash[:notice]).to eq('User created successfully')
      end
    end

    context 'when payment processing is required' do
      it 'processes payment and creates user' do
        payment_service = instance_double('PaymentService')
        allow(PaymentService).to receive(:new).and_return(payment_service)
        allow(payment_service).to receive(:charge).and_return(success: true, id: 'ch_123')

        post :create, params: {
          user: attributes_for(:user),
          payment: { amount: 100, token: 'tok_123' }
        }

        expect(response).to redirect_to(user_path(User.last))
        expect(flash[:notice]).to eq('Payment processed successfully')
      end
    end
  end
end
```

### Service Object Specs (`spec/services/`)
- Test business logic in isolation
- Use real models for internal operations created with FactoryBot
- Mock external dependencies using RSpec doubles

```ruby
RSpec.describe UserRegistrationService do
  describe '#register' do
    let(:email_service) { instance_double('EmailService') }
    let(:slack_service) { instance_double('SlackService') }

    subject(:service) do
      UserRegistrationService.new(
        email_service: email_service,
        slack_service: slack_service
      )
    end

    before do
      allow(email_service).to receive(:send_welcome_email)
      allow(slack_service).to receive(:notify_new_user)
    end

    it 'creates user and sends notifications' do
      user = service.register(name: "John Doe", email: "john@example.com")

      expect(user).to be_persisted
      expect(user.email).to eq("john@example.com")
      expect(email_service).to have_received(:send_welcome_email).with(user)
      expect(slack_service).to have_received(:notify_new_user).with(user)
    end

    context 'when user creation fails' do
      it 'does not send notifications' do
        expect {
          service.register(name: "", email: "invalid")
        }.not_to change(User, :count)

        expect(email_service).not_to have_received(:send_welcome_email)
        expect(slack_service).not_to have_received(:notify_new_user)
      end
    end
  end
end
```

### Feature Specs with Cucumber (`features/`)
- Test complete user workflows end-to-end
- Use real database and models created with FactoryBot
- Mock only external APIs and services
- **Use Page Objects for all UI interactions**
- Focus on user behavior and business value

```gherkin
# features/user_registration.feature
Feature: User Registration
  As a potential customer
  I want to register for an account
  So that I can access the platform

  Background:
    Given the payment service is available
    And the email service is working

  Scenario: Successful user registration
    Given I am on the registration page
    When I fill in the registration form with valid details
    And I submit the form
    Then I should see a success message
    And I should be redirected to the dashboard
    And I should receive a welcome email

  Scenario: Registration with payment
    Given I am on the premium registration page
    When I fill in the registration form with valid details
    And I enter valid payment information
    And I submit the form
    Then I should see a payment success message
    And my account should be marked as premium
    And I should receive a premium welcome email

  Scenario: Registration form validation
    Given I am on the registration page
    When I submit the form with invalid data
    Then I should see validation errors
    And I should remain on the registration page
```

```ruby
# features/support/page_objects/base_page.rb
class BasePage
  include Capybara::DSL
  include RSpec::Matchers

  def initialize
    # Common page functionality
  end

  def current_path
    URI.parse(current_url).path
  end

  def has_flash_message?(message, type: :notice)
    has_css?(".flash.#{type}", text: message)
  end

  def wait_for_ajax
    Timeout.timeout(Capybara.default_max_wait_time) do
      loop until page.evaluate_script('jQuery.active').zero?
    end
  end
end

# features/support/page_objects/registration_page.rb
class RegistrationPage < BasePage
  def visit_page
    visit new_user_registration_path
  end

  def visit_premium_page
    visit new_premium_user_registration_path
  end

  def fill_in_user_details(user_attributes)
    fill_in 'user_name', with: user_attributes[:name]
    fill_in 'user_email', with: user_attributes[:email]
    fill_in 'user_password', with: user_attributes[:password]
    fill_in 'user_password_confirmation', with: user_attributes[:password]
  end

  def fill_in_payment_details(payment_info = {})
    fill_in 'payment_card_number', with: payment_info[:card_number] || '4242424242424242'
    fill_in 'payment_expiry', with: payment_info[:expiry] || '12/25'
    fill_in 'payment_cvc', with: payment_info[:cvc] || '123'
  end

  def submit_form
    click_button 'Create Account'
  end

  def submit_invalid_form
    fill_in 'user_name', with: ''
    fill_in 'user_email', with: 'invalid-email'
    click_button 'Create Account'
  end

  def has_validation_errors?
    has_css?('.field_with_errors') &&
    has_content?('Please review the problems below')
  end

  def has_success_message?
    has_flash_message?('Account created successfully!')
  end

  def has_payment_success_message?
    has_flash_message?('Payment processed and account created successfully!')
  end

  def on_registration_page?
    current_path == new_user_registration_path
  end
end

# features/support/page_objects/dashboard_page.rb
class DashboardPage < BasePage
  def visit_page
    visit dashboard_path
  end

  def has_welcome_message?(user_name)
    has_content?("Welcome, #{user_name}!")
  end

  def has_premium_badge?
    has_css?('.premium-badge')
  end

  def on_dashboard?
    current_path == dashboard_path
  end
end

# features/step_definitions/user_registration_steps.rb
Given('the payment service is available') do
  allow_any_instance_of(PaymentService).to receive(:charge)
    .and_return(success: true, id: 'ch_123')
end

Given('the email service is working') do
  allow(UserMailer).to receive(:welcome_email)
    .and_return(instance_double(ActionMailer::MessageDelivery, deliver_now: true))
  allow(UserMailer).to receive(:premium_welcome_email)
    .and_return(instance_double(ActionMailer::MessageDelivery, deliver_now: true))
end

Given('I am on the registration page') do
  @registration_page = RegistrationPage.new
  @registration_page.visit_page
end

Given('I am on the premium registration page') do
  @registration_page = RegistrationPage.new
  @registration_page.visit_premium_page
end

When('I fill in the registration form with valid details') do
  @user_attributes = attributes_for(:user)
  @registration_page.fill_in_user_details(@user_attributes)
end

When('I enter valid payment information') do
  @registration_page.fill_in_payment_details
end

When('I submit the form') do
  @registration_page.submit_form
end

When('I submit the form with invalid data') do
  @registration_page.submit_invalid_form
end

Then('I should see a success message') do
  expect(@registration_page).to have_success_message
end

Then('I should see a payment success message') do
  expect(@registration_page).to have_payment_success_message
end

Then('I should see validation errors') do
  expect(@registration_page).to have_validation_errors
end

Then('I should remain on the registration page') do
  expect(@registration_page).to be_on_registration_page
end

Then('I should be redirected to the dashboard') do
  @dashboard_page = DashboardPage.new
  expect(@dashboard_page).to be_on_dashboard
end

Then('I should receive a welcome email') do
  user = User.find_by(email: @user_attributes[:email])
  expect(UserMailer).to have_received(:welcome_email).with(user)
end

Then('I should receive a premium welcome email') do
  user = User.find_by(email: @user_attributes[:email])
  expect(UserMailer).to have_received(:premium_welcome_email).with(user)
end

Then('my account should be marked as premium') do
  user = User.find_by(email: @user_attributes[:email])
  expect(user.account_type).to eq('premium')
end

# features/support/env.rb
require 'cucumber/rails'

# Load page objects
Dir[Rails.root.join('features/support/page_objects/*.rb')].each { |f| require f }

# Make page objects available in step definitions
World(Module.new do
  def registration_page
    @registration_page ||= RegistrationPage.new
  end

  def dashboard_page
    @dashboard_page ||= DashboardPage.new
  end

  def admin_page
    @admin_page ||= AdminPage.new
  end
end)
```

## Code Quality Standards

### Rubocop Configuration Expectations
Claude Code should generate Ruby/Rails/RSpec code that adheres to our Rubocop standards:

```ruby
# Example of Rubocop-compliant RSpec code
RSpec.describe OrderCalculator do
  subject(:calculator) { described_class.new(tax_rate: tax_rate) }

  let(:tax_rate) { 0.08 }
  let(:order_total) { 100.00 }

  describe '#calculate_tax' do
    context 'with valid inputs' do
      it 'calculates tax correctly' do
        result = calculator.calculate_tax(order_total: order_total)

        expect(result).to eq(8.00)
      end
    end

    context 'with zero tax rate' do
      let(:tax_rate) { 0.0 }

      it 'returns zero tax' do
        result = calculator.calculate_tax(order_total: order_total)

        expect(result).to eq(0.0)
      end
    end
  end
end

# Rubocop-compliant service class
class OrderCalculator
  include ActiveModel::Validations

  validates :tax_rate, presence: true,
                       numericality: { greater_than_or_equal_to: 0 }

  def initialize(tax_rate:)
    @tax_rate = tax_rate
    validate!
  end

  def calculate_tax(order_total:)
    return 0.0 if tax_rate.zero?

    (order_total * tax_rate).round(2)
  end

  private

  attr_reader :tax_rate
end
```

### JSLint Standards for JavaScript/Stimulus
For the minimal JavaScript/Stimulus code we write:

```javascript
// JSLint-compliant Stimulus controller
import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["form", "submitButton"];
  static values = {
    endpoint: String,
    timeout: { type: Number, default: 5000 }
  };

  connect() {
    this.validateForm();
  }

  validateForm() {
    const isValid = this.formTarget.checkValidity();
    this.submitButtonTarget.disabled = !isValid;
  }

  async submitForm(event) {
    event.preventDefault();

    this.setSubmittingState();

    try {
      const response = await this.postData();
      this.handleSuccess(response);
    } catch (error) {
      this.handleError(error);
    } finally {
      this.resetSubmittingState();
    }
  }

  setSubmittingState() {
    this.submitButtonTarget.disabled = true;
    this.submitButtonTarget.textContent = "Processing...";
  }

  resetSubmittingState() {
    this.submitButtonTarget.disabled = false;
    this.submitButtonTarget.textContent = "Submit";
  }

  async postData() {
    const formData = new FormData(this.formTarget);

    const response = await fetch(this.endpointValue, {
      method: "POST",
      body: formData,
      headers: {
        "X-Requested-With": "XMLHttpRequest"
      }
    });

    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }

    return response.json();
  }

  handleSuccess(data) {
    // Handle successful response
    window.location = data.redirect_url;
  }

  handleError(error) {
    console.error("Form submission failed:", error);
    // Show user-friendly error message
  }
}
```

## Claude Code Instructions for TDD Workflow

### When Generating New Features:

1. **Always start with RED** - Generate failing tests first
2. **Write minimal GREEN implementation** - Just enough to pass tests
3. **Suggest REFACTOR opportunities** - Improvements while keeping tests green
4. **Follow our code quality standards** - Rubocop for Ruby, JSLint for JavaScript
5. **Use descriptive test names** - Focus on business behavior, not implementation
6. **Generate comprehensive test coverage** - Unit tests, integration tests, and feature specs when appropriate

### Test Generation Priorities:

1. **Model specs** - For business logic and validations
2. **Service specs** - For complex business operations
3. **Controller specs** - For request/response handling
4. **Feature specs** - For end-to-end user workflows
5. **Mailer specs** - For email functionality (separate from service tests)

### Example TDD Session Request:
```
"Please help me build a subscription renewal feature using TDD.
I need to:
1. Check if subscription is expiring within 7 days
2. Send renewal notification email
3. Update subscription status when renewed
4. Handle payment processing

Start with failing tests, then implement minimal functionality."
```

## Red Flags - When Tests Need Refactoring

❌ **Too many mocks in one test** (more than 2-3 usually indicates design issues)
❌ **Mocking method chains** (`allow(user.account.subscription.plan).to receive(:price)`)
❌ **Tests that break when refactoring internal code**
❌ **More mock setup than actual test assertions**
❌ **Mocking your own domain objects created with FactoryBot**
❌ **Tests longer than 10 lines** (Rubocop RSpec/ExampleLength violation)
❌ **Missing descriptive test names** that explain business value
❌ **Skipping the RED phase** - Writing implementation before failing test

## FactoryBot Best Practices

### Define Clean, Reusable Factories
```ruby
# spec/factories/users.rb
FactoryBot.define do
  factory :user do
    sequence(:name) { |n| "User #{n}" }
    sequence(:email) { |n| "user#{n}@example.com" }
    password { "password123" }
    active { true }

    trait :inactive do
      active { false }
    end

    trait :with_premium_account do
      account_type { 'premium' }
    end

    trait :with_orders do
      transient do
        orders_count { 3 }
      end

      after(:create) do |user, evaluator|
        create_list(:order, evaluator.orders_count, user: user)
      end
    end
  end
end

# spec/factories/orders.rb
FactoryBot.define do
  factory :order do
    user
    total { 100.00 }
    status { 'pending' }

    trait :completed do
      status { 'completed' }
      completed_at { 1.day.ago }
    end

    trait :with_line_items do
      transient do
        item_count { 2 }
      end

      after(:create) do |order, evaluator|
        create_list(:line_item, evaluator.item_count, order: order)
      end
    end
  end
end
```

### Usage Examples
```ruby
# Simple object creation
user = create(:user)
order = create(:order, user: user)

# Using traits
premium_user = create(:user, :with_premium_account)
completed_order = create(:order, :completed)

# Complex object graphs
user_with_orders = create(:user, :with_orders, orders_count: 5)
order_with_items = create(:order, :with_line_items, item_count: 3)

# Building without persistence (for unit tests)
user = build(:user, name: "Test User")
expect(user.display_name).to eq("Test User")
```

## Fixtures for File Testing Only

Use fixtures exclusively for test files needed for upload or data extraction testing:

```ruby
# spec/fixtures/files/
# - sample_upload.csv
# - test_image.jpg
# - sample_data.xlsx

RSpec.describe CsvImportService do
  describe '#import' do
    it 'imports users from CSV file' do
      file_path = Rails.root.join('spec', 'fixtures', 'files', 'sample_users.csv')

      service = CsvImportService.new
      result = service.import(file_path)

      expect(result.success?).to be true
      expect(User.count).to eq(3) # Based on fixture file content
    end
  end
end

RSpec.describe ImageProcessor do
  describe '#resize' do
    it 'resizes uploaded image' do
      image_path = Rails.root.join('spec', 'fixtures', 'files', 'test_image.jpg')

      processor = ImageProcessor.new
      result = processor.resize(image_path, width: 100, height: 100)

      expect(result).to be_success
    end
  end
end
```

## RSpec Configuration

### Recommended RSpec Setup
```ruby
# spec/rails_helper.rb
RSpec.configure do |config|
  # FactoryBot integration
  config.include FactoryBot::Syntax::Methods

  # Database cleaner for reliable test isolation
  config.use_transactional_fixtures = true

  # Filter lines from Rails gems in backtraces
  config.filter_rails_from_backtrace!

  # Mock external HTTP requests in test environment
  # config.before(:suite) do
  #   WebMock.disable_net_connect!(allow_localhost: true)
  # end
end

# spec/spec_helper.rb
RSpec.configure do |config|
  # Disable RSpec exposing methods globally on Module and main
  config.disable_monkey_patching!

  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Limit a spec run to individual examples or groups
  config.filter_run_when_matching :focus
end
```

## Business Context Considerations

Since this is a **Launch Scout project** with business development implications:

### Test Customer-Facing Features Thoroughly
- Use Cucumber features for critical user journeys
- Test error scenarios that affect customer experience
- Mock payment processing but test the complete checkout flow with RSpec request specs

### Test Business Logic with Real Data
- Financial calculations should use real arithmetic, not mocked results
- User permissions and access controls need real database relationships created with FactoryBot
- Reporting features should work with actual data structures

### Performance Considerations
- Mock only slow external dependencies with RSpec doubles
- Use real database for fast queries (Rails test DB is optimized)
- Use FactoryBot's `build` vs `create` strategically to reduce database hits

## Quick Reference for Common Scenarios

| Scenario | Approach | RSpec Example |
|----------|----------|---------------|
| User creates account | Real models, mock emails | `create(:user)` + `allow(UserMailer).to receive(:welcome_email)` |
| Payment processing | Real models, mock payment gateway | Real `Order` + `allow(PaymentService).to receive(:charge)` |
| File upload | Real models, mock file operations | Real `Document` + `allow(File).to receive(:write)` |
| API integration | Mock HTTP client | `instance_double('HttpClient')` |
| Background jobs | Real models, mock job execution | Real data + `allow(JobClass).to receive(:perform_later)` |
| Email content testing | Separate mailer spec, no mocking | Test mailer directly with real data |

## TDD Examples for Common Scenarios

### Model Development with TDD
```ruby
# RED: Start with failing model test
RSpec.describe User, type: :model do
  describe '#full_name' do
    it 'returns concatenated first and last name' do
      user = build(:user, first_name: 'John', last_name: 'Doe')

      expect(user.full_name).to eq('John Doe')
    end
  end

  describe '#premium?' do
    it 'returns true when account_type is premium' do
      user = build(:user, account_type: 'premium')

      expect(user).to be_premium
    end

    it 'returns false when account_type is basic' do
      user = build(:user, account_type: 'basic')

      expect(user).not_to be_premium
    end
  end
end

# GREEN: Implement minimal functionality
class User < ApplicationRecord
  def full_name
    "#{first_name} #{last_name}"
  end

  def premium?
    account_type == 'premium'
  end
end

# REFACTOR: Enhance while keeping tests green
class User < ApplicationRecord
  ACCOUNT_TYPES = %w[basic premium enterprise].freeze

  validates :account_type, inclusion: { in: ACCOUNT_TYPES }

  def full_name
    [first_name, last_name].compact.join(' ')
  end

  def premium?
    account_type == 'premium'
  end

  def enterprise?
    account_type == 'enterprise'
  end
end
```

### Service Object Development with TDD
```ruby
# RED: Write failing service test first
RSpec.describe UserRegistrationService do
  describe '#register' do
    let(:user_attributes) { attributes_for(:user) }
    let(:email_service) { instance_double('EmailService') }
    let(:service) { described_class.new(email_service: email_service) }

    before do
      allow(email_service).to receive(:send_welcome_email)
    end

    it 'creates a new user with provided attributes' do
      result = service.register(user_attributes)

      expect(result.user).to be_persisted
      expect(result.user.email).to eq(user_attributes[:email])
      expect(result).to be_success
    end

    it 'sends welcome email to new user' do
      result = service.register(user_attributes)

      expect(email_service).to have_received(:send_welcome_email)
        .with(result.user)
    end

    context 'when user creation fails' do
      let(:invalid_attributes) { { email: 'invalid' } }

      it 'returns failure result with errors' do
        result = service.register(invalid_attributes)

        expect(result).to be_failure
        expect(result.errors).to be_present
      end

      it 'does not send welcome email' do
        service.register(invalid_attributes)

        expect(email_service).not_to have_received(:send_welcome_email)
      end
    end
  end
end

# GREEN: Minimal implementation
class UserRegistrationService
  Result = Struct.new(:user, :success, :errors) do
    def success?
      success
    end

    def failure?
      !success
    end
  end

  def initialize(email_service:)
    @email_service = email_service
  end

  def register(user_attributes)
    user = User.new(user_attributes)

    if user.save
      @email_service.send_welcome_email(user)
      Result.new(user, true, [])
    else
      Result.new(user, false, user.errors)
    end
  end
end

# REFACTOR: Add robustness and error handling
class UserRegistrationService
  include ActiveModel::Validations

  Result = Struct.new(:user, :success, :errors) do
    def success?
      success
    end

    def failure?
      !success
    end
  end

  def initialize(email_service: EmailService.new)
    @email_service = email_service
  end

  def register(user_attributes)
    user = User.new(user_attributes)

    ActiveRecord::Base.transaction do
      if user.save
        send_welcome_email_safely(user)
        Result.new(user, true, [])
      else
        Result.new(user, false, user.errors.full_messages)
      end
    end
  rescue StandardError => e
    Rails.logger.error("User registration failed: #{e.message}")
    Result.new(user, false, ['Registration failed. Please try again.'])
  end

  private

  def send_welcome_email_safely(user)
    @email_service.send_welcome_email(user)
  rescue StandardError => e
    Rails.logger.error("Failed to send welcome email: #{e.message}")
    # Don't fail registration if email fails
  end
end
```

### Controller Development with TDD
```ruby
# RED: Controller test drives API design
RSpec.describe UsersController, type: :controller do
  describe 'POST #create' do
    let(:user_service) { instance_double('UserRegistrationService') }
    let(:user_attributes) { attributes_for(:user) }

    before do
      allow(UserRegistrationService).to receive(:new).and_return(user_service)
    end

    context 'when registration succeeds' do
      let(:user) { create(:user) }
      let(:success_result) do
        UserRegistrationService::Result.new(user, true, [])
      end

      before do
        allow(user_service).to receive(:register).and_return(success_result)
      end

      it 'redirects to user dashboard' do
        post :create, params: { user: user_attributes }

        expect(response).to redirect_to(dashboard_path)
      end

      it 'sets success flash message' do
        post :create, params: { user: user_attributes }

        expect(flash[:notice]).to eq('Welcome! Your account has been created.')
      end
    end

    context 'when registration fails' do
      let(:failure_result) do
        UserRegistrationService::Result.new(User.new, false, ['Email is invalid'])
      end

      before do
        allow(user_service).to receive(:register).and_return(failure_result)
      end

      it 're-renders new template' do
        post :create, params: { user: user_attributes }

        expect(response).to render_template(:new)
      end

      it 'sets error flash message' do
        post :create, params: { user: user_attributes }

        expect(flash[:alert]).to eq('Please review the errors below.')
      end
    end
  end
end

# GREEN: Minimal controller implementation
class UsersController < ApplicationController
  def create
    result = registration_service.register(user_params)

    if result.success?
      flash[:notice] = 'Welcome! Your account has been created.'
      redirect_to dashboard_path
    else
      flash[:alert] = 'Please review the errors below.'
      render :new
    end
  end

  private

  def user_params
    params.require(:user).permit(:name, :email, :password)
  end

  def registration_service
    @registration_service ||= UserRegistrationService.new
  end
end
```

### Feature Development with TDD (Cucumber + Page Objects)
```gherkin
# RED: Write failing feature first
Feature: User Registration
  As a potential customer
  I want to register for an account
  So that I can access the platform

  Scenario: Successful user registration
    Given I am on the registration page
    When I fill in valid registration details
    And I submit the registration form
    Then I should see a welcome message
    And I should be on the dashboard page
    And I should receive a welcome email
```

```ruby
# GREEN: Implement step definitions and page objects
Given('I am on the registration page') do
  @registration_page = RegistrationPage.new
  @registration_page.visit
end

When('I fill in valid registration details') do
  @user_attributes = attributes_for(:user)
  @registration_page.fill_in_registration_form(@user_attributes)
end

When('I submit the registration form') do
  @registration_page.submit_form
end

Then('I should see a welcome message') do
  expect(page).to have_content('Welcome! Your account has been created.')
end

Then('I should be on the dashboard page') do
  @dashboard_page = DashboardPage.new
  expect(@dashboard_page).to be_current_page
end

# REFACTOR: Enhance page objects and add error scenarios
class RegistrationPage < BasePage
  def visit
    visit new_user_registration_path
  end

  def fill_in_registration_form(attributes)
    fill_in 'user_name', with: attributes[:name]
    fill_in 'user_email', with: attributes[:email]
    fill_in 'user_password', with: attributes[:password]
    fill_in 'user_password_confirmation', with: attributes[:password]
  end

  def submit_form
    click_button 'Create Account'
  end

  def has_validation_error?(field, message)
    has_css?("#user_#{field}_error", text: message)
  end
end
```

## Remember

**The goal is confident, maintainable tests that catch real bugs.** Prefer real objects created with FactoryBot and integration testing over heavy mocking. Use RSpec mocks only at the boundaries where your application touches external systems.

When in doubt, ask: *"Am I testing my actual business logic, or am I testing that I called a mock correctly?"*