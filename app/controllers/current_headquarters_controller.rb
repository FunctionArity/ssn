# Super admins switch the sede they work in; it's kept in the session until they switch again or sign out.
class CurrentHeadquartersController < ApplicationController
  def update
    headquarter = Headquarter.find(params.expect(:headquarter_id))
    authorize headquarter, :switch?

    session[:headquarter_id] = headquarter.id
    redirect_to root_path, notice: t("current_headquarters.notices.switched", name: headquarter.city), status: :see_other
  end
end
