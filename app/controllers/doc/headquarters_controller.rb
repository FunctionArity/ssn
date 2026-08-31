class Doc::HeadquartersController < ApplicationController
  skip_before_action :authenticate_user!
  layout "doc"

  def index
    @headquarters = Headquarter.order(:country, :state, :city)
  end

  def show
    @headquarter = Headquarter.friendly.find(params[:id])
  end
end
