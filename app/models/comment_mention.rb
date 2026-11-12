# A user mentioned in a comment, and whether they have read it.
class CommentMention < ApplicationRecord
  belongs_to :comment
  belongs_to :user

  scope :unread, -> { where(read_at: nil) }
  # A super admin working in another sede only sees that sede's mentions.
  scope :in_current_sede, -> { where(comment: Comment.in_current_sede) }

  after_commit :broadcast_unread_count, on: %i[create update destroy]

  # Keeps the top nav indicator up to date in every open tab of the user.
  def self.broadcast_unread_count(user)
    Turbo::StreamsChannel.broadcast_replace_later_to [ user, :mentions ],
      target: "mentions_indicator",
      partial: "layouts/mentions_indicator",
      locals: { user: user }
  end

  def unread?
    read_at.nil?
  end

  # Keeps the first time it was read.
  def read!
    update!(read_at: Time.current) if unread?
  end

  def unread!
    update!(read_at: nil)
  end

  private

  def broadcast_unread_count
    self.class.broadcast_unread_count(user)
  end
end
