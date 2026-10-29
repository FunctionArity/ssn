require "test_helper"

class GuardInfoControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user  = users(:one)
    @guard = guards(:one)
    sign_in @user
  end

  test "should return PDF for guard" do
    get guard_info_url(@guard, format: :pdf)

    assert_response :success
    assert_equal "application/pdf", response.content_type
  end

  test "PDF response starts with PDF magic bytes" do
    get guard_info_url(@guard, format: :pdf)

    assert response.body.start_with?("%PDF")
  end

  test "PDF filename includes guard id" do
    get guard_info_url(@guard, format: :pdf)

    assert_match "guardia_#{@guard.id}.pdf", response.headers["Content-Disposition"]
  end

  test "should return PDF for guard with no services" do
    @guard.services.destroy_all

    get guard_info_url(@guard, format: :pdf)

    assert_response :success
    assert_equal "application/pdf", response.content_type
  end

  test "should return PDF for guard with multiple pages of services" do
    4.times do |i|
      @guard.services.create!(full_name: "Service #{i}", due_date: Date.current, created_by: @user)
    end

    get guard_info_url(@guard, format: :pdf)

    assert_response :success
    assert response.body.start_with?("%PDF")
  end

  test "pdf redirects to the stored PDF once the guard is confirmed" do
    @guard.pdf_file.attach(
      io: StringIO.new("%PDF-fake"),
      filename: "guardia_#{@guard.id}.pdf",
      content_type: "application/pdf"
    )

    get guard_info_url(@guard, format: :pdf)

    assert_redirected_to rails_blob_url(@guard.pdf_file, disposition: "inline")
  end

  test "page lives at /guard_info/:id and shows the guard header with its PDF embedded" do
    assert_equal "/guard_info/#{@guard.id}", guard_info_path(@guard)

    get guard_info_url(@guard)

    assert_response :success
    assert_equal "text/html", response.media_type
    assert_select "h2", text: /# #{@guard.day_number}/
    assert_select "iframe[src=?]", guard_info_path(@guard, format: :pdf) + "#view=FitH"
    assert_select "a[href=?][target=_blank]", guard_info_path(@guard, format: :pdf) + "#view=FitH"
    assert_select ".border-t a[href=?]", guard_path(@guard), text: /#{I18n.t("guard_info.show.back")}/
  end

  # Same access as the guard show page: any signed-in user, vocal or not.
  test "a guardian who is not a vocal can see the page and the PDF, like the guard page" do
    sign_in users(:two)

    get guard_url(@guard)
    assert_response :success

    get guard_info_url(@guard)
    assert_response :success

    get guard_info_url(@guard, format: :pdf)
    assert_response :success
  end

  test "new previews the PDF at /guard_info/:id/new" do
    assert_equal "/guard_info/#{@guard.id}/new", new_guard_info_path(@guard)

    get new_guard_info_url(@guard)

    assert_response :success
  end

  test "new confirm button sets the confirm dialog title" do
    get new_guard_info_url(@guard)

    assert_select "form[action='#{guard_info_path(@guard)}'] input[type=submit][data-turbo-confirm-title='¿ Finalizar Guardia ?']"
  end

  test "new defaults first_nro to 1 when no services have nro assigned" do
    Service.update_all(nro: nil)

    get new_guard_info_url(@guard)

    assert_match "Primer Servicio NRO:", response.body
    assert_match 'value="1"', response.body
  end

  test "new defaults first_nro to last nro plus one" do
    services(:one).update!(nro: 10)

    get new_guard_info_url(@guard)

    assert_match 'value="11"', response.body
  end

  test "new uses provided first_nro param" do
    get new_guard_info_url(@guard), params: { first_nro: 5 }

    assert_match 'value="5"', response.body
  end

  test "new assigns sequential nro values to services starting from first_nro" do
    @guard.services.create!(full_name: "Extra", due_date: Date.current + 1, status: :completed, created_by: @user)
    get new_guard_info_url(@guard), params: { first_nro: 3 }

    assert_match "NRO 3", response.body
    assert_match "NRO 4", response.body
  end

  test "new does not persist nro values to database" do
    get new_guard_info_url(@guard), params: { first_nro: 99 }

    assert_nil services(:one).reload.nro
  end

  test "create saves nro values to services in order" do
    @guard.services.destroy_all
    service1 = @guard.services.create!(full_name: "A", due_date: Date.current - 1, status: :completed, created_by: @user)
    service2 = @guard.services.create!(full_name: "B", due_date: Date.current,     status: :completed, created_by: @user)

    post guard_info_url(@guard), params: { first_nro: 5 }

    assert_equal 5, service1.reload.nro
    assert_equal 6, service2.reload.nro
  end

  test "create attaches pdf_file to guard" do
    assert_not @guard.pdf_file.attached?

    post guard_info_url(@guard), params: { first_nro: 1 }

    assert @guard.reload.pdf_file.attached?
    assert_match %r{\A#{@guard.id}/[a-z0-9]{28}\z}, @guard.pdf_file.blob.key
  end

  test "create closes the guard" do
    assert @guard.open?

    post guard_info_url(@guard), params: { first_nro: 1 }

    assert @guard.reload.closed?
  end

  test "create redirects to the information page" do
    post guard_info_url(@guard), params: { first_nro: 1 }

    assert_redirected_to guard_info_url(@guard)
  end

  test "requires authentication" do
    sign_out @user

    get guard_info_url(@guard)

    assert_redirected_to new_user_session_url
  end
end
