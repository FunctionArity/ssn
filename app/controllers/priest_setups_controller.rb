class PriestSetupsController < ApplicationController
  before_action :set_priest_setup, only: %i[destroy]

  def assign
    assignments = PriestSetup.includes(:priest).index_by { |ps| [ ps.week_number, ps.day_of_week ] }
    @day_slots = (1..5).flat_map do |week|
      (0..6).map do |day|
        { week_number: week, day_of_week: day, assignment: assignments[[ week, day ]] }
      end
    end
    @priests = User.priests_without_setup.order(:first_name, :last_name)
  end

  def create
    PriestSetup.find_by(
      week_number: priest_setup_params[:week_number],
      day_of_week: priest_setup_params[:day_of_week]
    )&.destroy

    @priest_setup = PriestSetup.new(priest_setup_params)

    respond_to do |format|
      if @priest_setup.save
        format.html { redirect_to assign_priest_setups_path, notice: t("priest_setups.notices.created") }
        format.json { render json: @priest_setup, status: :created }
      else
        format.html { redirect_to assign_priest_setups_path, alert: @priest_setup.errors.full_messages.join(", ") }
        format.json { render json: @priest_setup.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @priest_setup.destroy!

    respond_to do |format|
      format.html { redirect_to assign_priest_setups_path, notice: t("priest_setups.notices.destroyed"), status: :see_other }
      format.json { head :no_content }
    end
  end

  private

  def set_priest_setup
    @priest_setup = PriestSetup.find(params.expect(:id))
  end

  def priest_setup_params
    params.expect(priest_setup: [ :priest_id, :week_number, :day_of_week ])
  end
end
