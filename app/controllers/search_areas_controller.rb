class SearchAreasController < ApplicationController
  before_action :set_search_area, only: [:show, :edit, :update, :destroy]

  # GET /search_areas
  # GET /search_areas.json
  def index
    @search_areas = SearchArea.all
    if params[:bounds]
      loc = Geokit::Geocoders::GoogleGeocoder.geocode(params[:bounds])
      bounds = loc.suggested_bounds
      @search_areas = @search_areas.where(lat: (bounds.sw.lat..bounds.ne.lat), lng: (bounds.sw.lng..bounds.ne.lng))
    end
    if params[:city_id]
      @search_areas = @search_areas.where(city_id: params[:city_id])
    end
    @search_areas = @search_areas.sort_by(&:total).reverse
  end

  # GET /search_areas/1
  # GET /search_areas/1.json
  def show
    if @search_area.statistics.keys.size > 2
      if params[:interval]
        sdate = @search_area.statistics.keys[1].to_date
        edate = Date.today
        stime = Time.new(sdate.year, sdate.month, sdate.day, 0, 0, 0, @search_area.zone)
        etime = Time.new(edate.year, edate.month, edate.day, 0, 0, 0, @search_area.zone)
        @medias = @search_area.medias.where(created_time: (stime..etime))

        interval = params[:interval].to_i
        time_splits = stime.to_i.step(etime.to_i, interval).to_a
        i = 0
        media_splites = time_splits.map do |t|
          while @medias[i] && @medias[i].created_time.to_i < t
            i += 1
          end
          i
        end
        data = media_splites.each_cons(2).map{ |s, t| t - s }
      else
        sdate = @search_area.statistics.keys[1].to_date
        edate = @search_area.statistics.keys.last.to_date
        stime = Time.new(sdate.year, sdate.month, sdate.day, 0, 0, 0, @search_area.zone)
        etime = Time.new(edate.year, edate.month, edate.day, 0, 0, 0, @search_area.zone)

        data = @search_area.statistics.values[1...-1].map{|s| s[:total]}
        interval = 1.day
      end


      @count = LazyHighCharts::HighChart.new('graph') do |f|
        f.title(:text => "Medias Count")
        f.xAxis(type: "datetime", maxZoom: (etime - stime).to_i)
        f.series(
          name: "count", 
          yAxis: 0, 
          data: data,
          pointStart: stime,
          pointInterval: interval
        )

        f.yAxis [
          {:title => {:text => "count", :margin => 70}, min: 0 },
        ]

        f.legend(:align => 'right', :verticalAlign => 'top', :y => 75, :x => -50, :layout => 'vertical',)
        f.chart({:defaultSeriesType=>"spline"})
      end

      distributions = @search_area.statistics.values[1...-1].map{|s| s[:distribution]}
      distribution_data = distributions.inject([]) do |res, d|
        d.each_with_index do |c, i|
          res[i] ||= []
          res[i] << c
        end
        res
      end
      distribution_data.each{ |d| d.extend(DescriptiveStatistics) }

      @distribution = LazyHighCharts::HighChart.new('graph') do |f|
        f.title(:text => "Medias Distribution")
        f.xAxis(
          categories: 24.times.map{ |h| ("%02d" % h) + ":00" }
        )
        f.series(
          name: 'mean',
          yAxis: 0,
          data: distribution_data.map(&:mean)
        )
        f.series(
          name: 'standard eviation',
          yAxis: 0,
          data: distribution_data.map(&:standard_deviation)
        )
        f.yAxis [
          {min: 0}
        ]
        f.legend(:align => 'right', :verticalAlign => 'top', :y => 150, :x => -50, :layout => 'vertical',)
        f.chart({:defaultSeriesType=>"spline"})
      end
    end
  end

  # GET /search_areas/new
  def new
    @search_area = SearchArea.new
  end

  # GET /search_areas/1/edit
  def edit
  end

  # POST /search_areas
  # POST /search_areas.json
  def create
    @search_area = SearchArea.new(search_area_params)

    respond_to do |format|
      if @search_area.save
        format.html { redirect_to @search_area, notice: 'Search area was successfully created.' }
        format.json { render :show, status: :created, location: @search_area }
      else
        format.html { render :new }
        format.json { render json: @search_area.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /search_areas/1
  # PATCH/PUT /search_areas/1.json
  def update
    respond_to do |format|
      if @search_area.update(search_area_params)
        format.html { redirect_to @search_area, notice: 'Search area was successfully updated.' }
        format.json { render :show, status: :ok, location: @search_area }
      else
        format.html { render :edit }
        format.json { render json: @search_area.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /search_areas/1
  # DELETE /search_areas/1.json
  def destroy
    @search_area.destroy
    respond_to do |format|
      format.html { redirect_to search_areas_url, notice: 'Search area was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_search_area
      @search_area = SearchArea.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def search_area_params
      params.require(:search_area).permit(:lat, :lng, :cycle, :time_zone)
    end
end
