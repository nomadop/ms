class CreateTagDicts < ActiveRecord::Migration
  def change
    create_table :tag_dicts do |t|
      t.string :catalog
      t.string :regexp

      t.timestamps
    end
  end
end
