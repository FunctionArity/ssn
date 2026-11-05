# A comment on any Commentable record (services today, guards next), written by a user.
class Comment < ApplicationRecord
  belongs_to :commentable, polymorphic: true
  belongs_to :user
  # The comment this one replies to. Deleting a comment keeps its replies, as top-level comments.
  belongs_to :parent, class_name: "Comment", optional: true, inverse_of: :replies
  has_many :replies, class_name: "Comment", foreign_key: :parent_id, inverse_of: :parent, dependent: :nullify
  has_many :mentions, class_name: "CommentMention", dependent: :destroy

  # Characters of visible text; the markup doesn't count.
  MAX_LENGTH = 500

  validates :body, presence: true
  validate :body_length
  validate :parent_on_same_record

  before_validation :clear_blank_body
  after_save :sync_mentions, if: :saved_change_to_body?

  scope :newest_first, -> { order(created_at: :desc, id: :desc) }

  # How a reply from the given user starts: mentioning the author and everyone else this comment mentions.
  def reply_body_for(replier)
    links = { user_id => "@#{user.full_name}" }.merge(Mentions.links(body)).except(replier.id)
    "<p>#{Mentions.to_html(links)}&nbsp;</p>"
  end

  def was_edited?
    updated_at > created_at
  end

  private

  # Every newly mentioned user, except the author, gets the comment as unread and by email. After an edit,
  # users no longer mentioned lose it, and those still mentioned keep theirs as it was, read or not.
  def sync_mentions
    mentioned_ids = User.mentionable.where(id: Mentions.user_ids(body) - [ user_id ]).ids
    mentions.where.not(user_id: mentioned_ids).destroy_all

    User.where(id: mentioned_ids - mentions.pluck(:user_id)).find_each do |mentioned|
      mentions.create!(user: mentioned)
      CommentMailer.with(comment: self, user: mentioned).mention.deliver_later
    end
  end

  def body_length
    errors.add(:body, :too_long, count: MAX_LENGTH) if Mentions.text(body).length > MAX_LENGTH
  end

  def parent_on_same_record
    return if parent.nil? || (parent.commentable_type == commentable_type && parent.commentable_id == commentable_id)

    errors.add(:parent, :invalid)
  end

  def clear_blank_body
    self.body = nil if Mentions.blank?(body)
  end
end
