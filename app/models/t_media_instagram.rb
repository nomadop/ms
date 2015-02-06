class TMediaInstagram < ActiveRecord::Base
  establish_connection :hk_development
  self.table_name = "t_media_instagram"
  self.inheritance_column = 'object_type'

  attr_accessor :results

  after_initialize :init_results

  class Result
    attr_accessor :age, :gender, :race, :height, :width

    def initialize json
      @age = (json['age']['value'] - json['age']['range']..json['age']['value'] + json['age']['range'])
      @gender = json['gender']['value'] == 'Male' ? json['gender']['confidence'] : 100 - json['gender']['confidence']
      @race = json['race']['value']
      @height = json['position']['height']
      @width = json['position']['width']
    end

    def size
      height * width
    end
  end

  def ll
    "#{latitude},#{longitude}"
  end

  def as_json *args
    super.merge(results: results.as_json)
  end

  def couple?
    return false unless results.size == 2
    a, b = results
    results.all?{ |r| r.age.any?{ |age| age > 15 && age < 45 } } && (a.age.to_a & b.age.to_a).any? &&
    (80..120).include?(a.gender + b.gender) && (a.gender - b.gender).abs > 20
  end

  private
  def init_results
    # self.detect_result = JSON.parse(detect_result) if detect_result.is_a?(String)
    @results = JSON.parse(detect_result).map{ |r| Result.new(r) }
  end
end
