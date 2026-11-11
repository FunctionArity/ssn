# Checks an ID token Google signed, like the one One Tap gives the page, and returns its claims: the user's email
# and whether Google verified it. Only tokens Google issued for this app's client, still valid, are accepted.
class GoogleIdToken
  CERTS_URL = URI("https://www.googleapis.com/oauth2/v3/certs")
  ISSUERS = %w[accounts.google.com https://accounts.google.com].freeze

  def self.client_id
    Rails.application.credentials.dig(:google, :client_id)
  end

  # The token's claims, or nil when it isn't a valid token for this app.
  def self.verify(token)
    return if token.blank? || client_id.blank?

    payload, _header = JWT.decode(token, nil, true, algorithms: [ "RS256" ], jwks: method(:jwks),
                                  iss: ISSUERS, verify_iss: true, aud: client_id, verify_aud: true)
    payload
  rescue JWT::DecodeError
    nil
  end

  # Google's public keys. It rotates them, so a token signed with a key we don't have fetches them again,
  # at most every 5 minutes so bad tokens can't make us hammer Google.
  #
  # race_condition_ttl keeps a cache miss from sending one outbound request per concurrent sign-in: while one
  # caller refreshes, others get the stale value instead of all fetching at once.
  def self.jwks(options = {})
    force = options[:kid_not_found] && refresh_due?
    cached = Rails.cache.fetch(:google_jwks, race_condition_ttl: 10.seconds, expires_in: 1.hour, force: force) do
      { keys: fetch_keys, fetched_at: Time.current }
    end
    cached[:keys]
  rescue SocketError, Timeout::Error, SystemCallError, JSON::ParserError => e
    Rails.logger.warn("GoogleIdToken: failed to fetch Google's JWKS: #{e.class}: #{e.message}")
    Rails.cache.read(:google_jwks)&.fetch(:keys) || []
  end

  def self.refresh_due?
    cached = Rails.cache.read(:google_jwks)
    cached.nil? || cached[:fetched_at] < 5.minutes.ago
  end
  private_class_method :refresh_due?

  def self.fetch_keys
    response = Net::HTTP.start(CERTS_URL.host, CERTS_URL.port, use_ssl: true, open_timeout: 5, read_timeout: 5) do |http|
      http.get(CERTS_URL)
    end
    JSON.parse(response.body)
  end
  private_class_method :fetch_keys
end
