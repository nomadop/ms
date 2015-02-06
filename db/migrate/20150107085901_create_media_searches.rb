class CreateMediaSearches < ActiveRecord::Migration
  def change
    create_table :media_searches do |t|
      t.float :lat
      t.float :lng
      t.integer :max_time
      t.integer :min_time
      t.integer :status, default: 0
      t.integer :media_count, default: 0

      t.timestamps
      t.index [:lat, :lng, :max_time, :min_time], name: 'media_searches_unique_index', unique: true
    end
  end
end
