require "test_helper"

class ContactDirectoriesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @headquarter = headquarters(:one)
    @directory = contact_directories(:pastoral)
    sign_in users(:admin_user)
  end

  test "shows a directory with its groups, contacts and call links" do
    get headquarter_contact_directory_url(@headquarter, @directory)

    assert_response :success
    assert_select "h1", @directory.title
    assert_select "h3", "Capital"
    assert_select "h3", "Maipú"
    assert_select "p", text: "en organización"
    assert_select "a[href='tel:2615087203']", text: /261 5087203/
    assert_select "a[href='https://wa.me/2615087203']"
  end

  test "regular users can see a directory but not its edit or delete actions" do
    sign_in users(:one)
    get headquarter_contact_directory_url(@headquarter, @directory)

    assert_response :success
    assert_select "a[href='#{edit_headquarter_contact_directory_path(@headquarter, @directory)}']", count: 0
    assert_select "form[action='#{headquarter_contact_directory_path(@headquarter, @directory)}'] input[value='delete']", count: 0
  end

  test "visitors must sign in to see a directory" do
    sign_out :user
    get headquarter_contact_directory_url(@headquarter, @directory)

    assert_redirected_to new_user_session_url
  end

  test "new starts with one empty group and contact" do
    get new_headquarter_contact_directory_url(@headquarter)

    assert_response :success
    assert_select "input[name='contact_directory[contact_groups_attributes][0][name]']"
    assert_select "input[name='contact_directory[contact_groups_attributes][0][contacts_attributes][0][name]']"
    assert_select "template input[name='contact_directory[contact_groups_attributes][NEW_GROUP][name]']"
    assert_select "template input[name='contact_directory[contact_groups_attributes][NEW_GROUP][contacts_attributes][0][name]']"
  end

  test "creates a directory with nested groups and contacts" do
    assert_difference -> { ContactDirectory.count } => 1, -> { ContactGroup.count } => 2, -> { Contact.count } => 3 do
      post headquarter_contact_directories_url(@headquarter), params: { contact_directory: {
        title: "Coordinadores", group_label: "Zona", visibility: "public",
        contact_groups_attributes: {
          "0" => { name: "Norte", contacts_attributes: { "0" => { name: "Ana", phone: "261 1" }, "1" => { name: "Beto" } } },
          "1" => { name: "Sur", notes: "nueva", contacts_attributes: { "0" => { name: "Carla", email: "carla@example.com" } } }
        }
      } }
    end

    directory = ContactDirectory.order(:id).last
    assert_redirected_to headquarter_contact_directory_url(@headquarter, directory)
    assert directory.visibility_public?
    assert_equal %w[Norte Sur], directory.contact_groups.map(&:name)
  end

  test "create re-renders the form when invalid" do
    assert_no_difference -> { ContactDirectory.count } do
      post headquarter_contact_directories_url(@headquarter), params: { contact_directory: {
        title: "", contact_groups_attributes: { "0" => { name: "Norte" } }
      } }
    end

    assert_response :unprocessable_entity
  end

  test "update edits, adds and removes nested records" do
    capital = contact_groups(:capital)
    maipu = contact_groups(:maipu)

    patch headquarter_contact_directory_url(@headquarter, @directory), params: { contact_directory: {
      title: "Referentes actualizados",
      contact_groups_attributes: {
        "0" => { id: capital.id, name: "Capital", contacts_attributes: {
          "0" => { id: contacts(:silvia).id, phone: "261 9999999" },
          "1" => { id: contacts(:liliana).id, _destroy: "1" },
          "2" => { name: "Nancy Bardisa", phone: "261 3644470" }
        } },
        "1" => { id: maipu.id, _destroy: "1" }
      }
    } }

    assert_redirected_to headquarter_contact_directory_url(@headquarter, @directory)
    @directory.reload
    assert_equal "Referentes actualizados", @directory.title
    assert_equal [ "Capital" ], @directory.contact_groups.map(&:name)
    assert_equal [ "Silvia Calderón", "Nancy Bardisa" ], capital.reload.contacts.map(&:name)
    assert_equal "261 9999999", contacts(:silvia).reload.phone
  end

  test "destroys a directory" do
    assert_difference -> { ContactDirectory.count }, -1 do
      delete headquarter_contact_directory_url(@headquarter, @directory)
    end

    assert_redirected_to headquarter_url(@headquarter)
  end

  test "non admin users cannot create, update or delete" do
    sign_in users(:one)

    get new_headquarter_contact_directory_url(@headquarter)
    assert_redirected_to root_path

    assert_no_difference -> { ContactDirectory.count } do
      post headquarter_contact_directories_url(@headquarter), params: { contact_directory: { title: "X" } }
    end
    assert_redirected_to root_path

    patch headquarter_contact_directory_url(@headquarter, @directory), params: { contact_directory: { title: "X" } }
    assert_redirected_to root_path
    assert_equal "Referentes Pastoral de la Salud", @directory.reload.title

    assert_no_difference -> { ContactDirectory.count } do
      delete headquarter_contact_directory_url(@headquarter, @directory)
    end
  end

  test "directories of another headquarter are not found through this one" do
    get headquarter_contact_directory_url(headquarters(:two), @directory)

    assert_response :not_found
  end

  test "headquarter page lists its directories and shows the new link to admins only" do
    get headquarter_url(@headquarter)
    assert_select "a[href='#{headquarter_contact_directory_path(@headquarter, @directory)}']", text: /#{@directory.title}/
    assert_select "a[href='#{new_headquarter_contact_directory_path(@headquarter)}']"

    sign_in users(:one)
    get headquarter_url(@headquarter)
    assert_select "a[href='#{headquarter_contact_directory_path(@headquarter, @directory)}']"
    assert_select "a[href='#{new_headquarter_contact_directory_path(@headquarter)}']", count: 0
  end

  test "public sede page shows public directories only" do
    sign_out :user
    get sede_url(@headquarter)

    assert_response :success
    assert_select "h2", contact_directories(:public_directory).title
    assert_select "h2", text: @directory.title, count: 0
    assert_select "a[href='mailto:capellan@example.com']"
  end
end
