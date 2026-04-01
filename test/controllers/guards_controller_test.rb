require "test_helper"

class GuardsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  # users(:one)       — vocal, vocal of guard_setup(:one) and guard(:one), guardian of guard(:one)
  # users(:vocal_guardian) — vocal role, guardian of guard(:one) but NOT its vocal
  # users(:unrelated_vocal) — vocal role, no relationship to guard(:one)
  # users(:two)       — guardian role (0), used as priest in guard(:one)

  setup do
    @user  = users(:one)
    @guard = guards(:one)
    sign_in @user
  end

  # ---------------------------------------------------------------------------
  # Read actions (no authorization enforced)
  # ---------------------------------------------------------------------------

  test "should get index" do
    get guards_url
    assert_response :success
  end

  test "should get show" do
    get guard_url(@guard)
    assert_response :success
  end

  # ---------------------------------------------------------------------------
  # new
  # ---------------------------------------------------------------------------

  test "should get new with guard_setup_id when user is vocal of that setup" do
    get new_guard_url, params: { guard_setup_id: guard_setups(:one).id }
    assert_response :success
  end

  test "new without guard_setup_id redirects to guards with alert" do
    travel_to(Time.current.change(day: 15)) do
      get new_guard_url
      assert_redirected_to guards_path
    end
  end

  test "new returns not found when guard_setup_id does not exist" do
    get new_guard_url, params: { guard_setup_id: -1 }
    assert_response :not_found
  end

  test "new forbidden for vocal user who is not vocal of the guard_setup" do
    sign_in users(:unrelated_vocal)
    get new_guard_url, params: { guard_setup_id: guard_setups(:one).id }
    assert_redirected_to root_path
  end

  test "new forbidden for non-vocal user" do
    sign_in users(:two)
    get new_guard_url, params: { guard_setup_id: guard_setups(:one).id }
    assert_redirected_to root_path
  end

  # ---------------------------------------------------------------------------
  # create
  # ---------------------------------------------------------------------------

  test "should create guard when user is vocal of the guard_setup" do
    assert_difference("Guard.count") do
      post guards_url, params: {
        guard: {
          day_number: 5,
          due_date: Date.today,
          notes: "New guard notes",
          vocal_id: users(:one).id,
          priest_id: users(:two).id,
          guard_setup_id: guard_setups(:one).id,
          guardian_ids: [ users(:one).id ]
        }
      }
    end

    assert_redirected_to guard_url(Guard.last)
  end

  test "should not create guard without guardians" do
    assert_no_difference("Guard.count") do
      post guards_url, params: {
        guard: {
          day_number: 5,
          due_date: Date.today,
          vocal_id: users(:one).id,
          priest_id: users(:two).id,
          guard_setup_id: guard_setups(:one).id,
          guardian_ids: []
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "create forbidden for vocal user who is not vocal of the guard_setup" do
    sign_in users(:unrelated_vocal)
    assert_no_difference("Guard.count") do
      post guards_url, params: {
        guard: {
          day_number: 5,
          due_date: Date.today,
          vocal_id: users(:unrelated_vocal).id,
          priest_id: users(:two).id,
          guard_setup_id: guard_setups(:one).id,
          guardian_ids: [ users(:unrelated_vocal).id ]
        }
      }
    end

    assert_redirected_to root_path
  end

  test "create forbidden for non-vocal user" do
    sign_in users(:two)
    assert_no_difference("Guard.count") do
      post guards_url, params: {
        guard: {
          day_number: 5,
          due_date: Date.today,
          vocal_id: users(:two).id,
          priest_id: users(:two).id,
          guard_setup_id: guard_setups(:one).id,
          guardian_ids: [ users(:two).id ]
        }
      }
    end

    assert_redirected_to root_path
  end

  # ---------------------------------------------------------------------------
  # edit
  # ---------------------------------------------------------------------------

  test "should get edit when user is the vocal of the guard" do
    get edit_guard_url(@guard)
    assert_response :success
  end

  test "edit forbidden for vocal user who is a guardian but not the vocal of the guard" do
    sign_in users(:vocal_guardian)
    get edit_guard_url(@guard)
    assert_redirected_to root_path
  end

  test "edit forbidden for vocal user with no relationship to the guard" do
    sign_in users(:unrelated_vocal)
    get edit_guard_url(@guard)
    assert_redirected_to root_path
  end

  test "edit forbidden for non-vocal user" do
    sign_in users(:two)
    get edit_guard_url(@guard)
    assert_redirected_to root_path
  end

  # ---------------------------------------------------------------------------
  # update
  # ---------------------------------------------------------------------------

  test "should update guard when user is the vocal of the guard" do
    new_notes = "Updated notes"
    patch guard_url(@guard), params: {
      guard: {
        day_number: @guard.day_number,
        notes: new_notes,
        vocal_id: @guard.vocal_id,
        priest_id: @guard.priest_id,
        guardian_ids: [ users(:one).id ]
      }
    }

    assert_redirected_to guard_url(@guard)
    assert_equal new_notes, @guard.reload.notes
  end

  test "should not update guard with invalid params" do
    patch guard_url(@guard), params: {
      guard: {
        day_number: nil,
        vocal_id: @guard.vocal_id,
        priest_id: @guard.priest_id,
        guardian_ids: [ users(:one).id ]
      }
    }

    assert_response :unprocessable_entity
    assert_equal 1, @guard.reload.day_number
  end

  test "update forbidden for vocal user who is a guardian but not the vocal of the guard" do
    sign_in users(:vocal_guardian)
    patch guard_url(@guard), params: {
      guard: {
        day_number: @guard.day_number,
        notes: "Updated by guardian vocal",
        vocal_id: @guard.vocal_id,
        priest_id: @guard.priest_id,
        guardian_ids: [ users(:one).id, users(:vocal_guardian).id ]
      }
    }

    assert_redirected_to root_path
  end

  test "update forbidden for vocal user with no relationship to the guard" do
    sign_in users(:unrelated_vocal)
    patch guard_url(@guard), params: {
      guard: {
        day_number: @guard.day_number,
        notes: "Should not update",
        vocal_id: @guard.vocal_id,
        priest_id: @guard.priest_id,
        guardian_ids: [ users(:one).id ]
      }
    }

    assert_redirected_to root_path
  end

  test "update forbidden for non-vocal user" do
    sign_in users(:two)
    patch guard_url(@guard), params: {
      guard: {
        day_number: @guard.day_number,
        notes: "Should not update",
        vocal_id: @guard.vocal_id,
        priest_id: @guard.priest_id,
        guardian_ids: [ users(:one).id ]
      }
    }

    assert_redirected_to root_path
  end

  # ---------------------------------------------------------------------------
  # destroy
  # ---------------------------------------------------------------------------

  test "should destroy guard when user is the vocal of the guard" do
    assert_difference("Guard.count", -1) do
      delete guard_url(@guard)
    end

    assert_redirected_to guards_url
  end

  test "should destroy guard along with its services" do
    @guard.services.create!(full_name: "Test", due_date: Date.today, created_by: @user)
    services_count = @guard.services.count

    assert_difference("Service.count", -services_count) do
      assert_difference("Guard.count", -1) do
        delete guard_url(@guard)
      end
    end

    assert_redirected_to guards_url
  end

  test "destroy forbidden for vocal user who is a guardian but not the vocal of the guard" do
    sign_in users(:vocal_guardian)
    assert_no_difference("Guard.count") do
      delete guard_url(@guard)
    end

    assert_redirected_to root_path
  end

  test "destroy forbidden for vocal user with no relationship to the guard" do
    sign_in users(:unrelated_vocal)
    assert_no_difference("Guard.count") do
      delete guard_url(@guard)
    end

    assert_redirected_to root_path
  end

  test "destroy forbidden for non-vocal user" do
    sign_in users(:two)
    assert_no_difference("Guard.count") do
      delete guard_url(@guard)
    end

    assert_redirected_to root_path
  end

  # ---------------------------------------------------------------------------
  # Other actions (close, pdf — no authorization enforced)
  # ---------------------------------------------------------------------------

  test "should close an open guard" do
    assert @guard.open?

    post close_guard_url(@guard)

    assert_redirected_to guard_url(@guard)
    assert @guard.reload.closed?
  end

  test "should not close an already closed guard" do
    @guard.closed!

    post close_guard_url(@guard)

    assert_redirected_to guard_url(@guard)
    assert @guard.reload.closed?
  end

  test "should return PDF for guard" do
    get pdf_guard_url(@guard)

    assert_response :success
    assert_equal "application/pdf", response.content_type
  end

  test "PDF response starts with PDF magic bytes" do
    get pdf_guard_url(@guard)

    assert response.body.start_with?("%PDF")
  end

  test "PDF filename includes guard id" do
    get pdf_guard_url(@guard)

    assert_match "guardia_#{@guard.id}.pdf", response.headers["Content-Disposition"]
  end

  test "should return PDF for guard with no services" do
    @guard.services.destroy_all

    get pdf_guard_url(@guard)

    assert_response :success
    assert_equal "application/pdf", response.content_type
  end

  test "should return PDF for guard with multiple pages of services" do
    4.times do |i|
      @guard.services.create!(full_name: "Service #{i}", due_date: Date.today, created_by: @user)
    end

    get pdf_guard_url(@guard)

    assert_response :success
    assert response.body.start_with?("%PDF")
  end

  test "pdf action redirects to stored blob when pdf_file is attached" do
    @guard.pdf_file.attach(
      io: StringIO.new("%PDF-fake"),
      filename: "guardia_#{@guard.id}.pdf",
      content_type: "application/pdf"
    )

    get pdf_guard_url(@guard)

    assert_response :redirect
  end

  # ---------------------------------------------------------------------------
  # preview
  # ---------------------------------------------------------------------------

  test "should get preview" do
    get preview_guard_url(@guard)

    assert_response :success
  end

  test "preview defaults first_nro to 1 when no services have nro assigned" do
    Service.update_all(nro: nil)

    get preview_guard_url(@guard)

    assert_match "Primer NRO:", response.body
    assert_match 'value="1"', response.body
  end

  test "preview defaults first_nro to last nro plus one" do
    services(:one).update!(nro: 10)

    get preview_guard_url(@guard)

    assert_match 'value="11"', response.body
  end

  test "preview uses provided first_nro param" do
    get preview_guard_url(@guard), params: { first_nro: 5 }

    assert_match 'value="5"', response.body
  end

  test "preview assigns sequential nro values to services starting from first_nro" do
    @guard.services.create!(full_name: "Extra", due_date: Date.today + 1, status: :completed, created_by: @user)
    get preview_guard_url(@guard), params: { first_nro: 3 }

    assert_match "NRO 3", response.body
    assert_match "NRO 4", response.body
  end

  test "preview does not persist nro values to database" do
    get preview_guard_url(@guard), params: { first_nro: 99 }

    assert_nil services(:one).reload.nro
  end

  # ---------------------------------------------------------------------------
  # confirm_pdf
  # ---------------------------------------------------------------------------

  test "confirm_pdf saves nro values to services in order" do
    @guard.services.destroy_all
    service1 = @guard.services.create!(full_name: "A", due_date: Date.today - 1, status: :completed, created_by: @user)
    service2 = @guard.services.create!(full_name: "B", due_date: Date.today,     status: :completed, created_by: @user)

    post confirm_pdf_guard_url(@guard), params: { first_nro: 5 }

    assert_equal 5, service1.reload.nro
    assert_equal 6, service2.reload.nro
  end

  test "confirm_pdf attaches pdf_file to guard" do
    assert_not @guard.pdf_file.attached?

    post confirm_pdf_guard_url(@guard), params: { first_nro: 1 }

    assert @guard.reload.pdf_file.attached?
  end

  test "confirm_pdf closes the guard" do
    assert @guard.open?

    post confirm_pdf_guard_url(@guard), params: { first_nro: 1 }

    assert @guard.reload.closed?
  end

  test "confirm_pdf redirects to pdf action" do
    post confirm_pdf_guard_url(@guard), params: { first_nro: 1 }

    assert_redirected_to pdf_guard_url(@guard)
  end
end
