# Emoji reactions to comments: each user can react to a comment once with each emoji.
class CreateCommentReactions < ActiveRecord::Migration[8.1]
  def change
    create_table :comment_reactions do |t|
      t.references :comment, null: false, foreign_key: { on_delete: :cascade }, index: false
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.string :emoji, null: false
      t.timestamps
    end
    add_index :comment_reactions, %i[comment_id user_id emoji], unique: true
  end
end
