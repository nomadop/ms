class AddIndexToMediaInstagrams < ActiveRecord::Migration
  def change
    add_index :media_instagrams, :created_time
  end
end
