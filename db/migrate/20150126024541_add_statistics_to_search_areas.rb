class AddStatisticsToSearchAreas < ActiveRecord::Migration
  def change
    add_column :search_areas, :statistics, :text
  end
end
