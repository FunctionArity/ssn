# Users imported from files got the shared password "password123", and invited ones a random one. Clearing it
# for those who never signed in closes that shared password; they show as pending and get in by accepting an
# invitation, which sets their own. Users who have signed in keep theirs.
class ClearPasswordsOfUsersWhoNeverSignedIn < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL
      UPDATE users
      SET encrypted_password = '', updated_at = CURRENT_TIMESTAMP
      WHERE last_sign_in_at IS NULL AND sign_in_count = 0 AND encrypted_password <> ''
    SQL
  end

  def down
    raise ActiveRecord::IrreversibleMigration, "The cleared password hashes can't be restored"
  end
end
