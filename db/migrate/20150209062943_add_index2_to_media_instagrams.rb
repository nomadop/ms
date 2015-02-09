class AddIndex2ToMediaInstagrams < ActiveRecord::Migration
  def change
    add_index :media_instagrams, :created_time_int
  end
end
