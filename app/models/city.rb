class City < ActiveRecord::Base

  serialize :suggest_bounds, Array
  has_many :search_areas

  def zone
    "#{time_zone >= 0 ? '+' : '-'}#{"%02d" % time_zone.abs}:00"
  end

  def statistics
    return @statistics unless @statistics.nil?
    result = search_areas.inject({}) do |res, area|
      area.statistics.keys.each do |date|
        statistic = area.statistics[date]
        res[date] = {total: 0, distribution: [0] * 24} if res[date].nil?
        res[date][:total] += statistic[:total]
        statistic[:distribution].each_with_index do |d, i|
          res[date][:distribution][i] += d
        end
      end
      res
    end
    @statistics = result.sort_by{|k, v| k.to_date}.inject({}) do |res, kvp|
      key, value = kvp
      res[key] = value
      res
    end
  end

  def bounds_center
    lat = (suggest_bounds[0][0] + suggest_bounds[1][0]) / 2
    lng = (suggest_bounds[0][1] + suggest_bounds[1][1]) / 2
    Geokit::LatLng.normalize(lat, lng)
  end

  def add_search_areas_from_bounds
    get_suggested_bounds
    locs = split_bounds
    locs.map do |loc|
      area = SearchArea.find_or_create_by(lat: loc.lat, lng: loc.lng, time_zone: time_zone)
      area.update(city_id: id) if area.city_id.nil?
    end
  end

  def split_bounds
    ys = suggest_bounds[0][0].round(2).step(suggest_bounds[1][0].round(2), 0.01).map{ |y| y.round(2) }
    xs = suggest_bounds[0][1].round(2).step(suggest_bounds[1][1].round(2), 0.01).map{ |x| x.round(2) }
    ys.flat_map{ |y| xs.map{ |x| Geokit::GeoLoc.normalize(y, x) } }
  end

  def get_suggested_bounds
    loc = Geokit::Geocoders::GoogleGeocoder.geocode(name)
    bounds = loc.suggested_bounds
    self.suggest_bounds = bounds.to_a
    save
  end

  private
  def init_serialize
    self.suggest_bounds ||= []
  end
end
