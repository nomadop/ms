class AddSearchAreaIdToMediaSearches < ActiveRecord::Migration
  def change
    add_column :media_searches, :search_area_id, :integer
  end
end
