class AddTimeZoneToSearchAreas < ActiveRecord::Migration
  def change
    add_column :search_areas, :time_zone, :integer, default: 0
  end
end
