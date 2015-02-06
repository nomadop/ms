class ChangeCycleOfSearchAreas < ActiveRecord::Migration
  def up
    change_column :search_areas, :cycle, :integer, default: 0
  end

  def down
    change_column :search_areas, :cycle, :integer, default: 86400
  end
end
