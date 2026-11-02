# frozen_string_literal: true

# Any signed-in user can join a conversation, so mentioned users can reply.
class CommentPolicy < ApplicationPolicy
  def create?
    user.present?
  end

  def destroy?
    super_admin? || record.user == user
  end

end
