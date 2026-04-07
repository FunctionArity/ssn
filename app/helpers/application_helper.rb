module ApplicationHelper
  def user_crown_icon(user = current_user)
    return if user&.regular?
    return tag.i class: "ph ph-crown-simple" if user&.admin?

    tag.i class: "ph ph-crown" if user&.super_admin?
  end

  def setup_active?
    setup_paths = %w[/guard_setups /priest_setups /users /health_facilities /churches]
    setup_paths.any? { |path| request.path.start_with?(path) }
  end
end
