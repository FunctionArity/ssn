require "test_helper"

class ContactTest < ActiveSupport::TestCase
  test "requires a name" do
    contact = Contact.new(contact_group: contact_groups(:capital))

    assert_not contact.valid?
    assert contact.errors[:name].any?
  end

  test "validates the email format when present" do
    contact = Contact.new(contact_group: contact_groups(:capital), name: "Ana", email: "no-es-un-email")
    assert_not contact.valid?

    contact.email = ""
    assert contact.valid?
  end

  test "phone_digits keeps only digits for tel and WhatsApp links" do
    assert_equal "2615087203", Contact.new(phone: "261 5087203").phone_digits
    assert_equal "5492614000000", Contact.new(phone: "+54 9 261-400-0000").phone_digits
    assert_equal "", Contact.new(phone: nil).phone_digits
  end

  test "groups require a name" do
    group = ContactGroup.new(contact_directory: contact_directories(:pastoral))

    assert_not group.valid?
    assert group.errors[:name].any?
  end
end
