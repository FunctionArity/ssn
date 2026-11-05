class CreateCommentMentions < ActiveRecord::Migration[8.1]
  def change
    create_table :comment_mentions do |t|
      t.references :comment, null: false, foreign_key: true, index: false
      t.references :user, null: false, foreign_key: true, index: false
      t.datetime :read_at

      t.timestamps
    end
    add_index :comment_mentions, %i[comment_id user_id], unique: true
    add_index :comment_mentions, %i[user_id read_at]
  end
end
