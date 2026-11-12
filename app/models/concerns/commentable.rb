# A record users can comment on, mentioning others with @. Include it, define `comment_subject` and add the model to
# Comment::COMMENTABLE_TYPES.
module Commentable
  extend ActiveSupport::Concern

  included do
    has_many :comments, as: :commentable, dependent: :destroy
  end

  # Name of the record in notifications, e.g. "te mencionaron en el servicio de <comment_subject>".
  def comment_subject
    raise NotImplementedError, "#{self.class} must define #comment_subject"
  end
end
