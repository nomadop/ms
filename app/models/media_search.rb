class MediaSearch < ActiveRecord::Base
  validates_presence_of :lat, :lng

  after_create :run_async

  belongs_to :search_area
  serialize :media_timestamps, Array

  scope :ready, ->{ where(status: 0) }
  scope :busy, ->{ where(status: 1) }
  scope :error, ->{ where(status: -1) }
  scope :finish, ->{ where(status: 2) }
  scope :success, ->{ where.not(media_count: 0) }

  def duration
    max_time - min_time if max_time && min_time
  end

  def find_search_area
    if search_area.nil?
      self.search_area = SearchArea.find_by(lat: lat, lng: lng)
      self.save
    end
  end

  def medias
    MediaInstagram.where("lat BETWEEN ? AND ? AND lng BETWEEN ? AND ? AND created_time BETWEEN ? AND ?", (lat - 0.005).round(3), (lat + 0.005).round(3), (lng - 0.005).round(3), (lng + 0.005).round(3), Time.at(min_time), Time.at(max_time)).order(:created_time)
  end

  def run
    if status <= 0
      ms = []
      begin
        update(status: 1)
        max, min = max_time, min_time
        mss = []
        loop do
          ms = InstagramCrawler.search_medias(lat, lng, max, min, time_zone)
          break if max.nil? || min.nil? || ms.empty? || max == ms.map(&:created_time).min.to_i
          mss += ms
          max = ms.map(&:created_time).min.to_i
        end
        mss = ms if mss.empty?
        update(media_count: mss.size, media_timestamps: mss.map{|m| m.created_time.to_i}, status: 2)
      rescue Exception => e
        update(status: -1)
        raise e
      end
      change_area_cycle
      if max_time && min_time && max_time - min_time < 3.month
        sdate = (Time.at(min_time).utc + search_area.time_zone.hours).to_date
        edate = (Time.at(max_time).utc + search_area.time_zone.hours).to_date
        while sdate <= edate
          search_area.analysis_statistics(sdate)
          sdate = sdate.tomorrow
        end
        search_area.save
      end
      ms
    end
  end

  def change_area_cycle
    find_search_area
    if media_count < 2 && search_area.cycle == 0
      search_area.update(cycle: 1.week)
      1
    elsif media_count > 50
      if search_area.cycle > SearchArea::CYCLE_TABLE.first
        index = SearchArea::CYCLE_TABLE.index(search_area.cycle)
        search_area.update(cycle: SearchArea::CYCLE_TABLE[index - 1])
      end
      2
    elsif search_area.cycle == 0
      min, max = media_timestamps.minmax
      search_area.update(
        cycle: case max - min
          when 0...6.hours
            6.hours
          when 6.hours...12.hours
            12.hours
          when 12.hours...1.day
            1.day
          when 1.day...2.days
            2.days
          when 2.days...4.days
            4.days
          else
            1.week
          end)
      3
    else
      0
    end
  end

  private
  def run_async
    MediaSearchWorker.perform_async(id)
  end

  def init_serialize
    self.media_timestamps ||= []
  end
end
