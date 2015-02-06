class CreateAuthentications < ActiveRecord::Migration
  def change
    create_table :authentications do |t|
      t.string :client_id, null: false
      t.string :client_secret, null: false
      t.string :redirect_uri, null: false
      t.string :access_token
      t.integer :client_count, default: 0

      t.timestamps
    end
  end
end
