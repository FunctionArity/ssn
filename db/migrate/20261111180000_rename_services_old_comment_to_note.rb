# The service's old comment becomes its note again, written in the Lexxy editor like before.
class RenameServicesOldCommentToNote < ActiveRecord::Migration[8.1]
  def change
    rename_column :services, :old_comment, :note
  end
end
