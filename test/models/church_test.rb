require "test_helper"

class ChurchTest < ActiveSupport::TestCase
  test "is valid with name only" do
    church = Church.new(name: "Parroquia Test")
    assert church.valid?
  end

  test "is valid with all fields" do
    church = Church.new(name: "Parroquia Test", phone: "4912149", address: "San Martin 100, Mendoza")
    assert church.valid?
  end

  test "is invalid without name" do
    church = Church.new(name: nil, address: "San Martin 100")
    assert_not church.valid?
    assert church.errors[:name].any?
  end

  test "phone and address are optional" do
    church = Church.new(name: "Parroquia Test", phone: nil, address: nil)
    assert church.valid?
  end

  test "has many priests" do
    church = churches(:one)
    assert_respond_to church, :priests
  end

  test "priest association is nullified when church is destroyed" do
    church = churches(:one)
    priest = users(:priest_one)
    priest.update!(church: church)

    church.destroy
    assert_nil priest.reload.church_id
  end
end
