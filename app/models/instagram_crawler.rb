module InstagramCrawler

  class ClientPool
    attr_accessor :max_size, :size, :clients, :resources

    def initialize max_size
      @max_size = max_size
      @size = 0
      @clients = Queue.new
      @resources = Queue.new
      max_size.times{ release_resource(Object.new) }
    end

    def get_resource
      resources.deq
    end

    def release_resource res
      resources.enq(res)
    end

    # def get_client
    #   if size < max_size
    #     begin
    #       clients.deq(true)
    #     rescue Exception => e
    #       client = InstagramCrawler.get_client
    #       @size += 1
    #       client
    #     end
    #   else
    #     clients.deq
    #   end
    # end

    # def release_client client
    #   clients.enq(client)
    # end

    def method_missing name, *args, &block
      super
    rescue NoMethodError, NameError => e1
      begin
        res = get_resource
        client = InstagramCrawler.get_client
        client.send(name, *args, &block)
      rescue Exception => e2
        if e2.message =~ /The access_token provided is invalid/
          access_token = client.access_token
          auth = Authentication.find_by(access_token: access_token)
          auth.get_access_token
        end
        raise e2
      ensure
        release_resource(res)
      end
    end
  end

  CALLBACK_URL = 'http://asia.senscape.com.cn/users/login'
  CLIENT_POOL = ClientPool.new(10)

  module_function
  def search_medias lat, lng, max_time = nil, min_time = nil, time_zone = 0
    medias = CLIENT_POOL.media_search(lat, lng, max_timestamp: max_time, min_timestamp: min_time, distance: 500)
    medias.map do |media|
      media.time_zone = time_zone
      MediaInstagram.create_from_hashie(media)
    end
  end

  def add_search_areas_from_bounds name, time_zone
    bounds = get_suggested_bounds(name)
    locs = split_bounds(bounds)
    locs.each do |loc|
      SearchArea.find_or_create_by(lat: loc.lat, lng: loc.lng, time_zone: time_zone)
    end
  end

  def search_medias_from_bounds name, max_time = nil, min_time = nil
    bounds = get_suggested_bounds(name)
    locs = split_bounds(bounds)
    locs.each do |loc|
      if max_time
        min_time.step(max_time, 1.days.to_i).each_cons(2) do |min, max|
          # MediaSearchWorker.perform_async(loc.lat, loc.lng, max, min)
          MediaSearch.create(lat: loc.lat, lng: loc.lng, max_time: max, min_time: min)
        end
      else
        # MediaSearchWorker.perform_async(loc.lat, loc.lng)
        MediaSearch.create(lat: loc.lat, lng: loc.lng)
      end
    end
  end

  def split_bounds bounds
    ys = bounds.sw.lat.round(2).step(bounds.ne.lat.round(2), 0.01).map{ |y| y.round(2) }
    xs = bounds.sw.lng.round(2).step(bounds.ne.lng.round(2), 0.01).map{ |x| x.round(2) }
    ys.flat_map{ |y| xs.map{ |x| Geokit::GeoLoc.normalize(y, x) } }
  end

  def get_suggested_bounds name
    loc = Geokit::Geocoders::GoogleGeocoder.geocode(name)
    bounds = loc.suggested_bounds
  end
  
  def get_token username = 'meijingkk', password = 'Yunxd@0211', redirect_uri = CALLBACK_URL
    m = Mechanize.new { |agent| agent.user_agent_alias = 'Mac Safari' }
    sleep(1)
    m.get(Instagram.authorize_url(redirect_uri: redirect_uri, response_type: :token))
    if m.page.uri.path == "/accounts/login/"
      sleep(1)
      m.page.form{|f| f.username = username; f.password = password}.submit
    end
    m.page.uri.to_s.match(/access_token=(.*)$/)[1]
  end

  def get_client
    Authentication.order(:client_count).first.get_client
  end
end