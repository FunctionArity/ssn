require "test_helper"

class PriestSetupsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:admin_user)
    @priest_setup = priest_setups(:one)
    sign_in @user
  end

  test "should create priest setup" do
    assert_difference("PriestSetup.count") do
      post priest_setups_url, params: {
        priest_setup: {
          priest_id: users(:priest_two).id,
          week_number: 3,
          day_of_week: 5
        }
      }
    end

    assert_redirected_to new_priest_setup_url
  end

  test "should replace existing assignment when creating for same slot" do
    assert_no_difference("PriestSetup.count") do
      post priest_setups_url, params: {
        priest_setup: {
          priest_id: users(:priest_two).id,
          week_number: @priest_setup.week_number,
          day_of_week: @priest_setup.day_of_week
        }
      }
    end

    assert_redirected_to new_priest_setup_url
    assert_equal users(:priest_two).id, PriestSetup.find_by(week_number: @priest_setup.week_number, day_of_week: @priest_setup.day_of_week).priest_id
  end

  test "should not create priest setup with invalid week_number" do
    assert_no_difference("PriestSetup.count") do
      post priest_setups_url, params: {
        priest_setup: {
          priest_id: users(:priest_one).id,
          week_number: 7,
          day_of_week: 1
        }
      }
    end

    assert_redirected_to new_priest_setup_url
  end

  test "should get index" do
    get priest_setups_url
    assert_response :success
  end

  test "should get index for a specific month using m parameter" do
    get priest_setups_url, params: { m: 3 }
    assert_response :success
    expected_month = I18n.l(Date.current.change(month: 3), format: "%B %Y")
    assert_match expected_month, response.body
  end

  test "should use current month when m parameter is absent" do
    get priest_setups_url
    assert_response :success
    expected_month = I18n.l(Date.current, format: "%B %Y")
    assert_match expected_month, response.body
  end

  test "should destroy priest setup" do
    assert_difference("PriestSetup.count", -1) do
      delete priest_setup_url(@priest_setup)
    end

    assert_redirected_to new_priest_setup_url
  end

  test "new shows every slot, with its priest, and the priests without one" do
    unassigned = User.create!(email: "priest.new@example.test", first_name: "Nuevo", last_name: "Sacerdote", role: :priest, password: "password123")

    get new_priest_setup_url

    assert_response :success
    # Four weeks of seven days, then the 29th to the 31st.
    assert_select "td[id^=priest_setup_cell_]", count: 31
    assert_select "#priest_setup_cell_5_3"
    assert_select "#priest_setup_cell_1_1", text: /#{users(:priest_one).full_name}/
    assert_select "#priests-panel [data-priest-id=?]", unassigned.id.to_s
    assert_select "#priests-panel [data-priest-id=?]", users(:priest_one).id.to_s, count: 0
  end

  test "moving an assignment to another slot empties the slot it came from" do
    assert_no_difference("PriestSetup.count") do
      post priest_setups_url, params: {
        source_setup_id: @priest_setup.id,
        priest_setup: { priest_id: @priest_setup.priest_id, week_number: 3, day_of_week: 5 }
      }, as: :turbo_stream
    end

    assert_not PriestSetup.exists?(@priest_setup.id)
    assert_equal @priest_setup.priest_id, PriestSetup.find_by(week_number: 3, day_of_week: 5).priest_id
    assert_select "turbo-stream[action=replace][target=priest_setup_cell_3_5]"
    assert_select "turbo-stream[action=replace][target=priest_setup_cell_#{@priest_setup.week_number}_#{@priest_setup.day_of_week}]"
  end

  test "a source slot that no longer exists is ignored" do
    assert_difference("PriestSetup.count") do
      post priest_setups_url, params: {
        source_setup_id: 0,
        priest_setup: { priest_id: users(:priest_two).id, week_number: 3, day_of_week: 5 }
      }, as: :turbo_stream
    end

    assert PriestSetup.exists?(@priest_setup.id)
    assert_select "turbo-stream[action=replace]", count: 1
  end

  # ---------------------------------------------------------------------------
  # Authorization — non-admin users
  # ---------------------------------------------------------------------------

  test "index shows new button to admin" do
    get priest_setups_url
    assert_select "a[href='#{new_priest_setup_path}']"
  end

  test "non-admin can get index without new button" do
    sign_in users(:one)
    get priest_setups_url
    assert_response :success
    assert_select "a[href='#{new_priest_setup_path}']", false
  end

  test "non-admin cannot get new" do
    sign_in users(:one)
    get new_priest_setup_url
    assert_redirected_to root_path
    assert_equal I18n.t("pundit.not_authorized"), flash[:alert]
  end

  test "non-admin cannot create priest setup" do
    sign_in users(:one)
    assert_no_difference("PriestSetup.count") do
      post priest_setups_url, params: {
        priest_setup: {
          priest_id: users(:priest_two).id,
          week_number: 3,
          day_of_week: 5
        }
      }
    end
    assert_redirected_to root_path
    assert_equal I18n.t("pundit.not_authorized"), flash[:alert]
  end

  test "non-admin create does not clear conflicting assignment" do
    sign_in users(:one)
    assert_no_difference("PriestSetup.count") do
      post priest_setups_url, params: {
        priest_setup: {
          priest_id: users(:priest_two).id,
          week_number: @priest_setup.week_number,
          day_of_week: @priest_setup.day_of_week
        }
      }
    end
    assert_redirected_to root_path
    assert_equal I18n.t("pundit.not_authorized"), flash[:alert]
    assert PriestSetup.exists?(@priest_setup.id), "existing assignment should not be cleared by an unauthorized request"
  end

  test "non-admin cannot destroy priest setup" do
    sign_in users(:one)
    assert_no_difference("PriestSetup.count") do
      delete priest_setup_url(@priest_setup)
    end
    assert_redirected_to root_path
    assert_equal I18n.t("pundit.not_authorized"), flash[:alert]
  end
end
