class SearchArea < ActiveRecord::Base
  validates_presence_of :lat, :lng

  after_initialize :init_serialize

  belongs_to :city
  has_many :media_searches
  serialize :statistics, Hash

  CYCLE_TABLE = [6.hours, 12.hours, 1.day, 2.days, 4.days, 1.week, 2.weeks, 1.month]

  def tags
    medias.flat_map(&:tags).group_by(&:to_s).sort_by{|k, v| v.count}.inject({}) do |res, kvp|
      k, v = kvp
      res[k] = v.count
      res
    end
  end

  def statistics_mean_by hour
    utc_hour = hour - time_zone
    utc_hour += 24 if utc_hour < 0
    res = MediaInstagram.where("lat BETWEEN ? AND ? AND lng BETWEEN ? AND ?", (lat - 0.005).round(3), (lat + 0.005).round(3), (lng - 0.005).round(3), (lng + 0.005).round(3)).where("created_time_int % 86400 BETWEEN ? AND ?", utc_hour.hours, (utc_hour + 1).hours).group("created_time_int / 86400").count
    distribution = res.sort_by{|k, v| k}[1...-1].map{|x| x[1]}
    distribution.extend(DescriptiveStatistics)
    distribution.mean
  end

  def get_distribution hour, method
    datas = statistics.values.map{ |s| s[:distribution][hour] }
    datas.extend(DescriptiveStatistics)
    datas.send(method)
  end

  def sort_statistics
    sorted_data = statistics.sort_by{ |k, v| k.to_date }
    self.statistics = sorted_data.inject({}) do |res, kvp|
      key, value = kvp
      res[key] = value
      res
    end
    save
  end

  def total
    statistics.values.sum{|d| d[:total]}
  end

  def zone
    "#{time_zone >= 0 ? '+' : '-'}#{"%02d" % time_zone.abs}:00"
  end

  def analysis_statistics date, ms = nil
    date = date.to_date
    stime = Time.new(date.year, date.month, date.day, 0, 0, 0, zone)
    etime = stime + 1.day
    ms ||= medias.where("created_time BETWEEN ? and ?", stime, etime)
    return false if ms.empty?
    time_splits = stime.to_i.step(etime.to_i, 1.hour).to_a
    i = 0
    media_splites = time_splits.map do |t|
      while ms[i] && ms[i].created_time.to_i < t
        i += 1
      end
      i
    end
    data = {
      total: ms.size,
      distribution: media_splites.each_cons(2).map{ |s, t| t - s }
    }
    self.statistics[date.to_s] = data
  end

  def south_area
    SearchArea.find_by(lat: (lat - 0.01).round(2), lng: lng)
  end

  def north_area
    SearchArea.find_by(lat: (lat + 0.01).round(2), lng: lng)
  end

  def west_area
    SearchArea.find_by(lat: lat, lng: (lng - 0.01).round(2))
  end

  def east_area
    SearchArea.find_by(lat: lat, lng: (lng + 0.01).round(2))
  end

  def check_cycle
    if media_searches.size >= 6 && cycle < SearchArea::CYCLE_TABLE.last
      searches = media_searches.order(:created_at).last(6)
      if searches.all?{|s| s.duration == cycle} && searches.map(&:media_count).each_slice(2).to_a.map(&:sum).all?{|s| s < 50} 
        index = SearchArea::CYCLE_TABLE.index(cycle)
        update(cycle: SearchArea::CYCLE_TABLE[index + 1])
      end
    end
  end

  def medias
    MediaInstagram.where("lat BETWEEN ? AND ? AND lng BETWEEN ? AND ?", (lat - 0.005).round(3), (lat + 0.005).round(3), (lng - 0.005).round(3), (lng + 0.005).round(3)).order(:created_time)
  end

  def search max_time = Time.now.to_i, min_time = last_searched_at, update_search_time = true
    MediaSearch.create(lat: lat, lng: lng, max_time: max_time, min_time: min_time, time_zone: time_zone, search_area_id: id)
    update(last_searched_at: max_time || Time.now.to_i) if update_search_time
  rescue Exception => e
    puts e
  end

  def history_search max_time = Time.now.to_i, min_time = max_time - 1.year, interval = 1.day
    min_time.step(max_time, interval).each_cons(2) do |min, max|
      search(max, min, false)
    end
  end

  def self.analysis_all
    areas = SearchArea.all
    areas.each do |area|
      area.statistics = {}
      ms = area.medias
      next if ms.empty?
      data = ms.group_by{ |m| (m.created_time.utc + area.time_zone.hours).to_date }
      data.keys[1...-1].each do |date|
        area.analysis_statistics(date, data[date])
      end
      area.save
    end
  end

  def self.cycle_check
    now = Time.now.to_i
    CycleCheckWorker.perform_in(1.hour)
    ready_areas = where("last_searched_at + cycle < ?", now)
    ready_areas.each do |a|
      if a.cycle == 0
        a.search(nil, nil)
      else
        a.check_cycle
        a.search(a.last_searched_at + a.cycle) if a.last_searched_at + a.cycle < now
      end
    end
  end

  private
  def init_serialize
    self.statistics ||= {}
  end
end
