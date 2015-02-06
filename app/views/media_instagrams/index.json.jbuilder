json.array!(@media_instagrams) do |media_instagram|
  json.extract! media_instagram, :id, :url, :media_type, :tags, :comment_count, :created_time, :location_id, :location_name, :lat, :lng, :width, :height
  json.url media_instagram_url(media_instagram, format: :json)
end
