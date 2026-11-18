# The API tokens users create for themselves (e.g. to try the API in Postman), so they can see and revoke them.
# Only the token's jti and its last characters are kept, never the token itself.
class CreatePersonalAccessTokens < ActiveRecord::Migration[8.1]
  def change
    create_table :personal_access_tokens do |t|
      t.references :user, null: false, foreign_key: true
      t.string :jti, null: false, index: { unique: true }
      t.string :hint, null: false
      t.datetime :expires_at, null: false

      t.timestamps
    end
  end
end
