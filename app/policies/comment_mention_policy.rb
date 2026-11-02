# frozen_string_literal: true
class CommentMentionPolicy < ApplicationPolicy

  def read?
    record.unread? || record.user == user
  end
end

