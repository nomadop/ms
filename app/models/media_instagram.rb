class MediaInstagram < ActiveRecord::Base
  validates_presence_of :media_id
  validates_uniqueness_of :media_id

  has_many :detect_results, dependent: :destroy
  serialize :filter_tags, Array
  serialize :tags, Array

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
end
