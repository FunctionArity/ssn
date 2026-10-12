require "test_helper"

class ContactDirectoryTest < ActiveSupport::TestCase
  test "requires a title" do
    directory = ContactDirectory.new(headquarter: headquarters(:one))

    assert_not directory.valid?
    assert directory.errors[:title].any?
  end

  test "is visible to members only by default" do
    assert ContactDirectory.new.visibility_members?
  end

  test "rejects an unknown visibility" do
    directory = ContactDirectory.new(headquarter: headquarters(:one), title: "X", visibility: "secret")

    assert_not directory.valid?
    assert directory.errors[:visibility].any?
  end

  test "creates groups and contacts through nested attributes, keeping their order" do
    directory = headquarters(:one).contact_directories.create!(
      title: "Referentes",
      contact_groups_attributes: [
        { name: "Norte", contacts_attributes: [ { name: "Liliana Llorca", phone: "261 6576845" }, { name: "Belen Ravera" } ] },
        { name: "Este", contacts_attributes: [ { name: "Oscar Suarez", detail: "Palmira" } ] }
      ]
    )

    assert_equal %w[Norte Este], directory.contact_groups.map(&:name)
    assert_equal [ "Liliana Llorca", "Belen Ravera" ], directory.contact_groups.first.contacts.map(&:name)
  end

  test "ignores blank nested groups and contacts" do
    directory = headquarters(:one).contact_directories.create!(
      title: "Referentes",
      contact_groups_attributes: [
        { name: "Norte", contacts_attributes: [ { name: "", detail: "", phone: "", email: "" } ] },
        { name: "", notes: "" }
      ]
    )

    assert_equal 1, directory.contact_groups.count
    assert_equal 0, directory.contact_groups.first.contacts.count
  end

  test "group_label_or_default falls back to a generic name" do
    assert_equal "Decanato", contact_directories(:pastoral).group_label_or_default
    assert_equal ContactDirectory.human_attribute_name(:default_group_label), ContactDirectory.new.group_label_or_default
  end

  test "destroying a directory removes its groups and contacts" do
    directory = contact_directories(:pastoral)

    assert_difference -> { ContactGroup.count } => -2, -> { Contact.count } => -2 do
      directory.destroy!
    end
  end

  test "destroying a headquarter removes its directories" do
    headquarter = headquarters(:one)

    assert_difference -> { ContactDirectory.count }, -2 do
      headquarter.destroy!
    end
  end

  test "records changes in the history" do
    contact = contacts(:silvia)

    assert_difference -> { contact.versions.count }, 1 do
      contact.update!(phone: "261 0000000")
    end
  end
end
