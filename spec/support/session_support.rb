def logout
  visit destroy_user_session_path
end

def login_as(user, password = 'password')
  visit new_user_session_path
  fill_in 'Email',    with: user.email
  fill_in 'Password', with: password
  click_button 'Sign in'
end

def sign_in_for_request(user, password = 'password')
  post user_session_path, params: {
    user: {
      email: user.email,
      password: password
    }
  }

  # Attempt to extract session token from response
  if response.status == 302 && response.headers['Set-Cookie']
    # Store the session for subsequent requests
    @session_cookies = response.headers['Set-Cookie']
  end
end

def make_authenticated_request(method, path, **options)
  headers = options[:headers] || {}
  headers['Cookie'] = @session_cookies if @session_cookies
  send(method, path, **options.merge(headers: headers))
end
