class CreateDetectResults < ActiveRecord::Migration
  def change
    create_table :detect_results do |t|
      t.integer :media_instagram_id
      t.integer :age_range
      t.integer :age_value
      t.float :gender_conf
      t.string :gender_value
      t.float :race_conf
      t.string :race_value
      t.float :smiling
      t.float :pitch_angle
      t.float :roll_angle
      t.float :yaw_angle
      t.float :center_x
      t.float :center_y
      t.float :width
      t.float :height

      t.timestamps
    end
  end
end
