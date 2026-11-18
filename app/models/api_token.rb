# The token the React front end sends as "Authorization: Bearer <token>" to the JSON API (/api/v1). It names the user
# and expires; changing the password (or anything Devise uses for its salt) invalidates the tokens issued before, and
# signing out (DELETE /api/v1/session) revokes it by putting its jti on JwtDenylist.
class ApiToken
  ALGORITHM = "HS256".freeze
  TTL = 12.hours

  def self.issue(user, now: Time.current, ttl: TTL, jti: SecureRandom.uuid)
    payload = { sub: user.id, ver: fingerprint(user), jti: jti, iat: now.to_i, exp: (now + ttl).to_i }
    JWT.encode(payload, secret, ALGORITHM)
  end

  # The user the token was issued to, or nil when it is invalid, expired, revoked or stale, or the user can't sign in
  # any more.
  def self.user_for(token)
    payload = decode(token)
    return if payload.nil? || JwtDenylist.revoked?(payload["jti"])

    user = User.in_any_sede.find_by(id: payload["sub"])
    return unless user&.active_for_authentication?

    user if ActiveSupport::SecurityUtils.secure_compare(payload["ver"].to_s, fingerprint(user))
  end

  # Refuses the token from now on, until it would have expired anyway.
  def self.revoke(token)
    payload = decode(token)
    JwtDenylist.revoke(payload["jti"], Time.zone.at(payload["exp"])) if payload
  end

  def self.decode(token)
    return if token.blank?

    JWT.decode(token, secret, true, algorithm: ALGORITHM, required_claims: %w[sub ver jti exp]).first
  rescue JWT::DecodeError
    nil
  end
  private_class_method :decode

  def self.secret
    Rails.application.key_generator.generate_key("api/v1 token", 32)
  end
  private_class_method :secret

  # Tied to the password: it is an HMAC, so the token, which anyone holding it can read, says nothing about the hash.
  def self.fingerprint(user)
    OpenSSL::HMAC.hexdigest("SHA256", secret, user.authenticatable_salt.to_s).first(16)
  end
  private_class_method :fingerprint
end
