# A comment can reply to another one of the same record. Deleting a comment keeps its replies, as top-level comments.
class AddParentToComments < ActiveRecord::Migration[8.1]
  def change
    add_reference :comments, :parent, foreign_key: { to_table: :comments, on_delete: :nullify }
  end
end
