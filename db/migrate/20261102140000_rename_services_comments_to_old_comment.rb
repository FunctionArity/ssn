# Frees the name for the comments a service can have, now in their own table.
class RenameServicesCommentsToOldComment < ActiveRecord::Migration[8.1]
  def change
    rename_column :services, :comments, :old_comment
  end
end
