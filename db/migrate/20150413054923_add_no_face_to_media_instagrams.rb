class AddNoFaceToMediaInstagrams < ActiveRecord::Migration
  def change
    add_column :media_instagrams, :no_face, :boolean, default: false
  end
end
