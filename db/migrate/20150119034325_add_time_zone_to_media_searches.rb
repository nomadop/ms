class AddTimeZoneToMediaSearches < ActiveRecord::Migration
  def change
    add_column :media_searches, :time_zone, :integer, default: 0
  end
end
