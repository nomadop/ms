class AddResultTimestampsToMediaSearches < ActiveRecord::Migration
  def change
    add_column :media_searches, :media_timestamps, :text
  end
end
