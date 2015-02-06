now = Time.now
loc = Geokit::LatLng.normalize(1.352083, 103.819836)
tasks = []
10.times.each_cons(2).flat_map do |i, j|
  puts "#{j} of 10..."
  tasks << Thread.new do
    InstagramCrawler::CLIENT_POOL.media_search(loc.lat, loc.lng, max_timestamp: (now - i.days).to_i, min_timestamp: (now - j.days).to_i)
  end
end