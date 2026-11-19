# The public documentation of the JSON API: a page that renders config/openapi.yaml with Scalar, and the spec itself
# as JSON, for Postman, client generators or anyone who wants to read it. Calling the API still needs a token.
class Doc::ApiController < ApplicationController
  skip_before_action :authenticate_user!
  # The page is its own HTML document: Scalar needs the whole viewport, under the public pages' navbar.
  layout false

  SPEC_PATH = Rails.root.join("config/openapi.yaml")

  # The spec with its YAML merge keys resolved. Read on each call so edits show up without a restart; it's small.
  def self.spec
    YAML.safe_load_file(SPEC_PATH, aliases: true)
  end

  def index
  end

  def spec
    expires_in 1.hour, public: true
    render json: self.class.spec
  end
end
