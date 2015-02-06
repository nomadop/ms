class AddUsernameAndPasswordToAuthentications < ActiveRecord::Migration
  def change
    add_column :authentications, :username, :string
    add_column :authentications, :password, :string
  end
end
