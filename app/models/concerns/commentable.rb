# A record users can comment on, mentioning others with @. Include it and define `comment_subject`.
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
