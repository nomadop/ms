class DetectResult < ActiveRecord::Base
  attr_accessor :age, :gender
  after_initialize :init_data

  belongs_to :media_instagram

  def left_top
    [(center_x - width / 2) / 100 * media_instagram.width , (center_y - height / 2) / 100 * media_instagram.height]
  end

  def right_top
    [(center_x + width / 2) / 100 * media_instagram.width , (center_y - height / 2) / 100 * media_instagram.height]
  end

  def left_bottom
    [(center_x - width / 2) / 100 * media_instagram.width , (center_y + height / 2) / 100 * media_instagram.height]
  end

  def right_bottom
    [(center_x + width / 2) / 100 * media_instagram.width , (center_y + height / 2) / 100 * media_instagram.height]
  end

  def real_center_x
    center_x / 100 * media_instagram.width
  end

  def real_center_y
    center_y / 100 * media_instagram.height
  end

  def real_width
    width / 100 * media_instagram.width
  end

  def real_height
    height / 100 * media_instagram.height
  end

  private
  def init_data
    @age = (age_value - age_range..age_value + age_range)
    @gender = gender_value == 'Male' ? gender_conf : 100 - gender_conf
  end
end
