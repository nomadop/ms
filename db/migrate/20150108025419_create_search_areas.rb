class CreateSearchAreas < ActiveRecord::Migration
  def change
    create_table :search_areas do |t|
      t.float :lat
      t.float :lng
      t.integer :cycle, default: 86400

      t.timestamps
      t.index [:lat, :lng], unique: true
    end
  end
end
