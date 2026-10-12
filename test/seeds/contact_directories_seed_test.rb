require "test_helper"

class ContactDirectoriesSeedTest < ActiveSupport::TestCase
  SEED = Rails.root.join("db/seeds/contact_directories.rb")

  setup do
    @mendoza = headquarters(:one)
    @mendoza.contact_directories.where(title: "Referentes Pastoral de la Salud").destroy_all
  end

  def run_seed
    capture_io { load SEED }
  end

  test "imports Mendoza's Pastoral de la Salud referents" do
    assert_difference -> { ContactDirectory.count } => 1, -> { ContactGroup.count } => 8, -> { Contact.count } => 14 do
      run_seed
    end

    directory = @mendoza.contact_directories.find_by!(title: "Referentes Pastoral de la Salud")
    assert_equal "Asesor: P. Enrique López", directory.description
    assert_equal "Decanato", directory.group_label
    assert_equal Date.new(2025, 6, 1), directory.updated_on
    assert directory.visibility_members?

    assert_equal [ "Capital", "Guaymallén", "Godoy Cruz", "Luján", "Maipú", "Norte", "Este", "Uco" ], directory.contact_groups.map(&:name)

    capital = directory.contact_groups.find_by!(name: "Capital")
    assert_equal [ "Silvia Calderón", "Liliana Colombatti", "Alicia Furfere", "Nancy Bardisa" ], capital.contacts.map(&:name)

    maipu = directory.contact_groups.find_by!(name: "Maipú")
    assert_equal "en organización", maipu.notes
    assert_equal [ "Flavia" ], maipu.contacts.map(&:name)

    este = directory.contact_groups.find_by!(name: "Este")
    assert_equal [ [ "Oscar Suarez", "Palmira", "261 5532418" ], [ "Raúl Solis", "Diác. · El Carmen", "263 4592732" ] ],
                 este.contacts.map { |c| [ c.name, c.detail, c.phone ] }
  end

  test "running it again does not duplicate or overwrite the directory" do
    run_seed
    directory = @mendoza.contact_directories.find_by!(title: "Referentes Pastoral de la Salud")
    directory.update!(description: "Editado en la app")

    assert_no_difference [ "ContactDirectory.count", "ContactGroup.count", "Contact.count" ] do
      run_seed
    end
    assert_equal "Editado en la app", directory.reload.description
  end
end
