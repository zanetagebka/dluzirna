class Rack::Attack
  # Always allow requests from localhost
  safelist('allow from localhost') do |req|
    '127.0.0.1' == req.ip || '::1' == req.ip
  end

  # Throttle email sending to prevent abuse
  throttle('emails/ip', limit: 5, period: 1.hour) do |req|
    req.ip if req.path.include?('/debts') && req.post?
  end
  
  # Throttle login attempts per email
  throttle('logins/email', limit: 5, period: 20.minutes) do |req|
    if req.path == '/users/sign_in' && req.post?
      req.params['user']&.[]('email')&.presence
    end
  end
  
  # Throttle registration attempts per IP
  throttle('registrations/ip', limit: 3, period: 1.hour) do |req|
    req.ip if req.path == '/users' && req.post?
  end
  
  # Throttle debt access to prevent token enumeration
  throttle('debt_access/ip', limit: 10, period: 1.minute) do |req|
    req.ip if req.path.match?(/\/pohledavky\//)
  end
  
  # Block suspicious requests to admin areas
  blocklist('block suspicious admin access') do |req|
    Rack::Attack::Fail2Ban.filter("suspicious-admin-#{req.ip}", maxretry: 3, findtime: 1.minute, bantime: 5.minutes) do
      req.path.include?('/admin') && req.user_agent.blank?
    end
  end

  # Custom response for throttled requests
  self.throttled_response = lambda do |env|
    [429, {'Content-Type' => 'text/plain'}, ['Rate limit exceeded. Please try again later.']]
  end
end