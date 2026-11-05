# frozen_string_literal: true

# Any signed-in user can join a conversation, so mentioned users can reply.
class CommentPolicy < ApplicationPolicy
  def create?
    user.present?
  end

  def show?
    user.present?
  end

  # Only the author, and only while nobody has replied, so a reply never answers text that changed.
  def update?
    record.user == user && record.replies.none?
  end

  def destroy?
    super_admin? || record.user == user
  end
end
