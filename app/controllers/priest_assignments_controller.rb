class PriestAssignmentsController < ApplicationController
  before_action :build_day_slots

  def index
    @priests = User.priests_without_setup.order(:first_name, :last_name)
  end

  private

  def build_day_slots
    assignments = PriestSetup.includes(:priest).index_by { |ps| ps.week_and_day_of_month }
    @day_slots = (1..6).flat_map do |week|
      (1..7).map do |day|
        { week_number: week, day_of_week: day, assignment: assignments[[ week, day ]] }
      end
    end
  end
end
