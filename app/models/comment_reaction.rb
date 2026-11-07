# An emoji a user reacted to a comment with. Each user reacts to a comment at most once with each emoji.
class CommentReaction < ApplicationRecord
  # The emojis users can pick, in the order the picker and the comment show them.
  EMOJIS = %w[👍 ❤️ 😂 😮 😢 🙏].freeze

  belongs_to :comment
  belongs_to :user

  validates :emoji, inclusion: { in: EMOJIS }
  validates :emoji, uniqueness: { scope: %i[comment_id user_id] }
end
