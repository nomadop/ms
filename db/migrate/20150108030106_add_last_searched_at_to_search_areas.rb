class AddLastSearchedAtToSearchAreas < ActiveRecord::Migration
  def change
    add_column :search_areas, :last_searched_at, :integer, default: 0
  end
end
