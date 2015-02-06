class CreateMediaInstagrams < ActiveRecord::Migration
  def change
    create_table :media_instagrams do |t|
      t.string :url
      t.string :media_type
      t.text :tags
      t.integer :comment_count
      t.timestamp :created_time
      t.string :location_id
      t.string :location_name
      t.float :lat
      t.float :lng
      t.integer :width
      t.integer :height

      t.timestamps
    end
  end
end
