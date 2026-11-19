# An API token a user created for themselves on the API tokens page, to call the API from Postman and the like.
# It's an ordinary ApiToken that lasts LIFETIME; the row keeps its jti so the user can list and revoke it, and the
# last characters so they can tell their tokens apart. The token itself is shown once, when it's created.
class PersonalAccessToken < ApplicationRecord
  LIFETIME = 7.days

  belongs_to :user

  # The token itself, only right after generate_for.
  attr_accessor :token

  scope :active, -> { where(expires_at: Time.current..).order(created_at: :desc) }
  scope :expired, -> { where(expires_at: ...Time.current) }

  def self.generate_for(user, now: Time.current)
    jti = SecureRandom.uuid
    token = ApiToken.issue(user, now: now, ttl: LIFETIME, jti: jti)
    create!(user: user, jti: jti, hint: token.last(6), expires_at: now + LIFETIME).tap { |record| record.token = token }
  end

  # The token stops working at once, not when it expires.
  def revoke!
    transaction do
      JwtDenylist.revoke(jti, expires_at)
      destroy!
    end
  end
end
