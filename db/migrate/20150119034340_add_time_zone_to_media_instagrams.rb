class AddTimeZoneToMediaInstagrams < ActiveRecord::Migration
  def change
    add_column :media_instagrams, :time_zone, :integer, default: 0
  end
end
