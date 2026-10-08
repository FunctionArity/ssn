class SitemapsController < ApplicationController
  skip_before_action :authenticate_user!

  def index
    @headquarters = Headquarter.order(:country, :state, :city)

    respond_to do |format|
      format.xml
    end
  end
end
