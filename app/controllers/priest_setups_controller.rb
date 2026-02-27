class PriestSetupsController < ApplicationController
  before_action :set_priest_setup, only: %i[destroy]
  before_action :clear_previous_assignments, only: %i[create]
  def create
    @priest_setup = PriestSetup.new(priest_setup_params)

    respond_to do |format|
      if @priest_setup.save
        format.html { redirect_to priest_assignments_path, notice: t("priest_setups.notices.created") }
        format.json { render json: @priest_setup, status: :created }
      else
        format.html { redirect_to priest_assignments_path, alert: @priest_setup.errors.full_messages.join(", ") }
        format.json { render json: @priest_setup.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @priest_setup.destroy!

    respond_to do |format|
      format.html { redirect_to priest_assignments_path, notice: t("priest_setups.notices.destroyed"), status: :see_other }
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

  def clear_previous_assignments
    PriestSetup.find_by(
      week_number: priest_setup_params[:week_number],
      day_of_week: priest_setup_params[:day_of_week]
    )&.destroy

    PriestSetup.find_by(id: params[:source_setup_id])&.destroy if params[:source_setup_id].present?

  end
end
