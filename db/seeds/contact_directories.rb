# Contact directories of each headquarter, transcribed from the printed sheets they keep.
# A directory that already exists (same headquarter and title) is left untouched, so edits made in the app are kept.
#
# Source: "Referentes Pastoral de la Salud" sheet of Mendoza, June 2025.
#   - Maipú: "Dalinda Miguel" is crossed out by hand on the sheet; only Flavia is listed, still being organized.
#   - Alicia Furfere: the number has one digit fewer than the others; it is copied as printed.

directories = [
  {
    headquarter: { city: "Mendoza", state: "Mendoza" },
    title: "Referentes Pastoral de la Salud",
    description: "Asesor: P. Enrique López",
    group_label: "Decanato",
    updated_on: Date.new(2025, 6, 1),
    visibility: :members,
    groups: [
      {
        name: "Capital",
        contacts: [
          { name: "Silvia Calderón", phone: "261 5087203" },
          { name: "Liliana Colombatti", phone: "261 5184357" },
          { name: "Alicia Furfere", phone: "261 455538" },
          { name: "Nancy Bardisa", phone: "261 3644470" }
        ]
      },
      {
        name: "Guaymallén",
        contacts: [
          { name: "Dalinda Agostini", phone: "261 6629145" }
        ]
      },
      {
        name: "Godoy Cruz",
        contacts: [
          { name: "Miguel Jaime", phone: "261 4712537" }
        ]
      },
      {
        name: "Luján",
        contacts: [
          { name: "Flavia Negre", phone: "261 5736805" }
        ]
      },
      {
        name: "Maipú",
        notes: "en organización",
        contacts: [
          { name: "Flavia" }
        ]
      },
      {
        name: "Norte",
        contacts: [
          { name: "Liliana Llorca", phone: "261 6576845" },
          { name: "Belen Ravera", phone: "261 5965514" },
          { name: "Mirian Forquera", phone: "261 6178591" }
        ]
      },
      {
        name: "Este",
        contacts: [
          { name: "Oscar Suarez", detail: "Palmira", phone: "261 5532418" },
          { name: "Raúl Solis", detail: "Diác. · El Carmen", phone: "263 4592732" }
        ]
      },
      {
        name: "Uco",
        contacts: [
          { name: "Adrian Cortez", phone: "261 3361967" }
        ]
      }
    ]
  }
]

directories.each do |data|
  headquarter = Headquarter.find_by(data[:headquarter])
  unless headquarter
    puts "Skipped contact directory #{data[:title]}: headquarter #{data[:headquarter].values.join(', ')} not found"
    next
  end

  if headquarter.contact_directories.exists?(title: data[:title])
    puts "Contact directory #{data[:title]} (#{headquarter.city}) already exists, left untouched"
    next
  end

  begin
    headquarter.contact_directories.create!(
      data.slice(:title, :description, :group_label, :updated_on, :visibility).merge(
        contact_groups_attributes: data[:groups].map do |group|
          group.slice(:name, :notes).merge(contacts_attributes: group[:contacts])
        end
      )
    )
    puts "Seeded contact directory #{data[:title]} (#{headquarter.city}) with #{data[:groups].size} groups"
  rescue ActiveRecord::RecordInvalid => e
    puts "Validation failed for contact directory #{data[:title]}: #{e.record.errors.full_messages.join(', ')}"
  end
end
