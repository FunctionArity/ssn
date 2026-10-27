class HomeController < ApplicationController
  skip_before_action :authenticate_user!, raise: false

  def index
    if user_signed_in?
      @current_guard = Guard.includes(:priest, :vocal, :guardians).find_by(due_date: Date.current)
      @previous_guard = Guard.includes(:priest, :vocal).where("due_date < ?", Date.current).order(due_date: :desc).first
      @next_guard = Guard.includes(:priest, :vocal).where("due_date > ?", Date.current).order(due_date: :asc).first
    end
  end
end
