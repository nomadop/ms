json.array!(@cities) do |city|
  json.extract! city, :id, :name, :code, :time_zone, :suggest_bounds
  json.url city_url(city, format: :json)
end
