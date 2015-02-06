json.array!(@search_areas) do |search_area|
  json.extract! search_area, :id, :lat, :lng, :cycle, :time_zone
  json.url search_area_url(search_area, format: :json)
end
