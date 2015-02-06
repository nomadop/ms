class AddFilterTagsToMediaInstagrams < ActiveRecord::Migration
  def change
    add_column :media_instagrams, :filter_tags, :text
  end
end
