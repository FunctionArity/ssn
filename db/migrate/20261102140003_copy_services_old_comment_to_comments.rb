# Each service's old comment becomes the first comment of its conversation, by the service's creator.
# old_comment is kept as a backup. Plain SQL, so no mention emails or unread marks are created.
class CopyServicesOldCommentToComments < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL
      INSERT INTO comments (commentable_type, commentable_id, user_id, body, created_at, updated_at)
      SELECT 'Service', id, created_by_id, old_comment, created_at, created_at
      FROM services
      WHERE btrim(coalesce(old_comment, '')) <> ''
    SQL
  end

  def down
    execute <<~SQL
      DELETE FROM comments
      USING services
      WHERE comments.commentable_type = 'Service'
        AND comments.commentable_id = services.id
        AND comments.body = services.old_comment
        AND comments.created_at = services.created_at
    SQL
  end
end
