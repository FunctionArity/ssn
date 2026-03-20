module ApplicationHelper
  def user_crown_icon(user = current_user)
    return if user&.regular?
    return tag.i class: "ph ph-crown-simple" if user&.admin?

    tag.i class: "ph ph-crown" if user&.super_admin?
  end
end
