class MediaInstagram < ActiveRecord::Base
  validates_presence_of :media_id
  validates_uniqueness_of :media_id

  has_many :detect_results, dependent: :destroy
  serialize :filter_tags, Array
  serialize :tags, Array

  before_save :set_created_time_int
  after_initialize :init_serialize

  Filters = [:couple?, :family?, :friends?, :group?]

  def ll
    "#{lat},#{lng}"
  end

  def couple?
    return false unless detect_results.size == 2
    a, b = detect_results
    detect_results.all?{ |r| (15..45).include?(r.age_value) } && 
    (a.age.to_a & b.age.to_a).size >= [a.age_range, b.age_range].max / 2 &&
    (80..120).include?(a.gender + b.gender) && (a.gender - b.gender).abs > 20
  end

  def family?
    return false unless (2..5).include?(detect_results.size)
    detect_results.any?{ |r| r.age_value + r.age_range <= 15 } &&
    detect_results.to_a.count{ |r| (20..45).include?(r.age_value) } < 3 &&
    (detect_results.one?{ |r| (20..45).include?(r.age_value) && r.gender > 50 } ||
      detect_results.one?{ |r| (20..45).include?(r.age_value) && r.gender <= 50 })
  end

  def friends?
    return false unless (4..10).include?(detect_results.size)
    detect_results.map(&:age).map(&:to_a).reduce(:&).size >= detect_results.map(&:age_range).max / 2
  end

  def group?
    detect_results.size > 10
  end

  def self.statistics_by opts = {}
    default_options = {
      lat: nil, # 纬度
      lng: nil, # 经度
      radius: 0.31, # 半径, 单位英里
      hours: (6..8), # 目标时间段, 取值范围0~23, 对应 0:00 至 23:00
      zone: 8, # 时区, 整形, 正数代表 GMT+n 时区, 负数代表 GMT-n 时区, 0 代表 UTC
      methods: [:sum, :mean, :standard_deviation], # 统计方法, sum: 总和, mean: 期望, max, min: 极值, standard_deviation: 方差 etc.
    }
    options = default_options.merge(opts)
    options[:hours] = Array(options[:hour]) unless options[:hour].nil?
    s_hour = options[:hours].map(&:to_i).min - options[:zone].to_i
    e_hour = options[:hours].map(&:to_i).max - options[:zone].to_i + 1
    res = []
    if s_hour * e_hour > 0
      if s_hour < 0
        s_hour += 24
        e_hour += 24
      end
      res = where_by_geoloc(options[:lat].to_f, options[:lng].to_f, options[:radius].to_f).where("created_time_int % 86400 BETWEEN ? AND ?", s_hour.hours, e_hour.hours).group("created_time_int / 86400").count
    else
      res = where_by_geoloc(options[:lat].to_f, options[:lng].to_f, options[:radius].to_f).where("created_time_int % 86400 BETWEEN ? AND ? OR created_time_int % 86400 BETWEEN ? AND ?", (s_hour + 24).hours, 24.hours, 0, e_hour.hours).group("created_time_int / 86400").count
    end
    distribution = res.sort_by{|k, v| k}[1...-1].map{|x| x[1]}
    distribution.extend(DescriptiveStatistics)
    options[:methods].inject({}) do |res, m|
      res[m] = distribution.send(m)
      res
    end
  end

  def self.where_by_geoloc lat, lng, radius
    where.not(lat: nil).where.not(lng: nil).where("#{distance_sql(lat, lng)} < ?", radius)
  end

  def self.distance_sql lat, lng
    latrad = deg2rad(lat)
    lngrad = deg2rad(lng)
    multiplier = 3963.1899999999996

    "(ACOS(least(1,COS(#{latrad})*COS(#{lngrad})*COS(RADIANS(media_instagrams.lat))*COS(RADIANS(media_instagrams.lng))+COS(#{latrad})*SIN(#{lngrad})*COS(RADIANS(media_instagrams.lat))*SIN(RADIANS(media_instagrams.lng))+SIN(#{latrad})*SIN(RADIANS(media_instagrams.lat))))*#{multiplier})"
  end

  def self.deg2rad(degrees)
    degrees.to_f / 180.0 * Math::PI
  end

  def self.img_wall medias
    size = medias.size
    cols = (size**0.5).round(0)
    rows = size % cols == 0 ? size / cols : size / cols + 1
    enum = medias.to_enum
    rows.times do |r|
      cols.times do |c|
        begin
          media = enum.next
          io = open(media.url)
        rescue Exception => e
          break
        end
      end
    end
  end

  def self.kmeans filter, centroids = 10
    medias = where("filter_tags LIKE ?", "%#{filter}%")
    miny, maxy = medias.map{ |m| m.lat }
    minx, maxx = medias.map{ |m| m.lng }
    data = medias.map do |m|
      y = (m.lat - miny) / (maxy - miny) * 1000
      x = (m.lng - minx) / (maxx - minx) * 1000
      [y, x]
    end
    kmeans = KMeans.new(data, centroids: centroids, distance_measure: :euclidean_distance)
    results = kmeans.view.map{ |v| v.map{ |x| medias[x] } }
  end

  def self.create_from_hashie hashie
    create(
      url: hashie.images.standard_resolution.url,
      media_id: hashie.id,
      media_type: hashie.type,
      tags: hashie.tags,
      comment_count: hashie.comments.count,
      created_time: Time.at(hashie.created_time.to_i),
      time_zone: hashie.time_zone,
      location_id: hashie.location.nil? ? nil : hashie.location.id,
      location_name: hashie.location.nil? ? nil : hashie.location.name,
      lat: hashie.location.nil? ? nil : hashie.location.latitude,
      lng: hashie.location.nil? ? nil : hashie.location.longitude,
      width: hashie.images.standard_resolution.width,
      height: hashie.images.standard_resolution.height
    )
  end

  def self.calculate_filters
    medias = all.includes(:detect_results)
    MediaInstagram.transaction do
      medias.each do |m|
        old_tags = m.filter_tags
        Filters.each do |filter|
          if m.send(filter)
            m.filter_tags << filter.to_s.chop
            m.filter_tags.uniq!
          elsif m.filter_tags.include?(filter.to_s.chop)
            m.filter_tags.delete(filter.to_s.chop)
          end
        end
        m.save if m.filter_tags != old_tags
      end
    end
  end

  private
  def init_serialize
    self.filter_tags ||= []
    self.tags ||= []
  end

  def set_created_time_int
    self.created_time_int = created_time.to_i
  end
end
