# API tokens signed out before they expired. A token whose jti is here is refused until it expires.
class JwtDenylist < ApplicationRecord
  scope :expired, -> { where(exp: ...Time.current) }

  def self.revoked?(jti)
    exists?(jti: jti)
  end

  # Revoking the same token twice is fine: a client may retry its sign-out.
  def self.revoke(jti, exp)
    upsert({ jti: jti, exp: exp }, unique_by: :jti)
  end
end
