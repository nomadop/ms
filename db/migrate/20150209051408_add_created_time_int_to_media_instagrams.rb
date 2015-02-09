class AddCreatedTimeIntToMediaInstagrams < ActiveRecord::Migration
  def change
    add_column :media_instagrams, :created_time_int, :integer
  end
end
