# The React front end (ssn-front) is served from its own origin and calls the JSON API with a bearer token, so only
# /api is open to it, and without cookies. API_CORS_ORIGINS lists its origins, comma separated; in development the
# Vite dev server's is the default.
origins = ENV.fetch("API_CORS_ORIGINS") { Rails.env.development? ? "http://localhost:5173" : "" }.split(",").map(&:strip).compact_blank

if origins.any?
  Rails.application.config.middleware.insert_before 0, Rack::Cors do
    allow do
      origins(*origins)
      resource "/api/*", headers: :any, methods: %i[get post put patch delete options head], credentials: false
    end
  end
end
