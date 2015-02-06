class CreateCities < ActiveRecord::Migration
  def change
    create_table :cities do |t|
      t.string :name
      t.string :code
      t.integer :time_zone
      t.text :suggest_bounds

      t.timestamps
    end
  end
end
