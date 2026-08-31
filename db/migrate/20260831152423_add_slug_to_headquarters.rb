class AddSlugToHeadquarters < ActiveRecord::Migration[8.1]
  class Headquarter < ActiveRecord::Base
  end

  def up
    add_column :headquarters, :slug, :string
    add_index :headquarters, :slug, unique: true

    Headquarter.reset_column_information
    Headquarter.find_each { |headquarter| headquarter.update_column(:slug, unique_slug_for(headquarter)) }

    change_column_null :headquarters, :slug, false
  end

  def down
    remove_column :headquarters, :slug
  end

  private

  def unique_slug_for(headquarter)
    candidates = [
      headquarter.city,
      "#{headquarter.city} #{headquarter.state}",
      "#{headquarter.city} #{headquarter.state} #{headquarter.country}"
    ].map { |candidate| candidate.parameterize }

    candidates.find { |candidate| slug_available?(candidate, headquarter.id) } ||
      "#{candidates.last}-#{headquarter.id}"
  end

  def slug_available?(slug, id)
    !Headquarter.where(slug: slug).where.not(id: id).exists?
  end
end
