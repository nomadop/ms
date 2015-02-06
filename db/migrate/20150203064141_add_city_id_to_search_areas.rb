class AddCityIdToSearchAreas < ActiveRecord::Migration
  def change
    add_column :search_areas, :city_id, :integer
  end
end
