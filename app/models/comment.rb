# A comment on any Commentable record (services today, guards next), written by a user.
class Comment < ApplicationRecord
  belongs_to :commentable, polymorphic: true
  belongs_to :user
  # The comment this one replies to. Deleting a comment deletes its replies too, and theirs, all the way down.
  belongs_to :parent, class_name: "Comment", optional: true, inverse_of: :replies
  has_many :replies, class_name: "Comment", foreign_key: :parent_id, inverse_of: :parent, dependent: :destroy
  has_many :mentions, class_name: "CommentMention", dependent: :destroy
  has_many :reactions, class_name: "CommentReaction", dependent: :delete_all

  # Characters of visible text; the markup doesn't count.
  MAX_LENGTH = 500

  # The models that include Commentable. Each record belongs to a sede.
  COMMENTABLE_TYPES = %w[Service].freeze

  validates :body, presence: true
  validate :body_length
  validate :parent_on_same_record

  before_validation :clear_blank_body
  after_save :sync_mentions, if: :saved_change_to_body?

  scope :newest_first, -> { order(created_at: :desc, id: :desc) }
  # Comments on records of the current sede, the ones the user can open: comments have no sede of their own.
  scope :in_current_sede, -> {
    COMMENTABLE_TYPES.map { |type| where(commentable_type: type, commentable_id: type.constantize.select(:id)) }.reduce(:or)
  }

  # How a reply from the given user starts: mentioning the author and everyone else this comment mentions.
  def reply_body_for(replier)
    links = { user_id => "@#{user.full_name}" }.merge(Mentions.links(body)).except(replier.id)
    "<p>#{Mentions.to_html(links)}&nbsp;</p>"
  end

  def was_edited?
    updated_at > created_at
  end

  private

  # Every newly mentioned user, except the author, gets the comment as unread, by email and as a push
  # notification on the devices where they turned those on. After an edit,
  # users no longer mentioned lose it, and those still mentioned keep theirs as it was, read or not.
  def sync_mentions
    mentioned_ids = User.mentionable.where(id: Mentions.user_ids(body) - [ user_id ]).ids
    mentions.where.not(user_id: mentioned_ids).destroy_all

    User.where(id: mentioned_ids - mentions.pluck(:user_id)).find_each do |mentioned|
      mention = mentions.create!(user: mentioned)
      CommentMailer.with(comment: self, user: mentioned).mention.deliver_later
      MentionPushJob.perform_later(mention)
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
