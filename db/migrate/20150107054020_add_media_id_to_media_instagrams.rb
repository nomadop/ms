class AddMediaIdToMediaInstagrams < ActiveRecord::Migration
  def change
    add_column :media_instagrams, :media_id, :string
    add_index :media_instagrams, :media_id, unique: true
  end
end
