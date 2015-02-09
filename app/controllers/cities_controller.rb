class CitiesController < ApplicationController
  before_action :set_city, only: [:show, :edit, :update, :destroy, :create_search_areas]

  def create_search_areas
    @city.add_search_areas_from_bounds

    render :show, status: :ok, location: @city
  end

  # GET /cities
  # GET /cities.json
  def index
    @cities = City.all
  end

  # GET /cities/1
  # GET /cities/1.json
  def show
    if @city.statistics.size > 2
      sdate = @city.statistics.keys[1].to_date
      edate = @city.statistics.keys.last.to_date
      stime = Time.new(sdate.year, sdate.month, sdate.day, 0, 0, 0, @city.zone)
      etime = Time.new(edate.year, edate.month, edate.day, 0, 0, 0, @city.zone)

      data = @city.statistics.values[1...-1].map{|s| s[:total]}
      interval = 1.day

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

      distributions = @city.statistics.values[1...-1].map{|s| s[:distribution]}
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

  # GET /cities/new
  def new
    @city = City.new
  end

  # GET /cities/1/edit
  def edit
  end

  # POST /cities
  # POST /cities.json
  def create
    @city = City.new(city_params)

    respond_to do |format|
      if @city.save
        format.html { redirect_to @city, notice: 'City was successfully created.' }
        format.json { render :show, status: :created, location: @city }
      else
        format.html { render :new }
        format.json { render json: @city.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /cities/1
  # PATCH/PUT /cities/1.json
  def update
    respond_to do |format|
      if @city.update(city_params)
        format.html { redirect_to @city, notice: 'City was successfully updated.' }
        format.json { render :show, status: :ok, location: @city }
      else
        format.html { render :edit }
        format.json { render json: @city.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /cities/1
  # DELETE /cities/1.json
  def destroy
    @city.destroy
    respond_to do |format|
      format.html { redirect_to cities_url, notice: 'City was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_city
      @city = City.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def city_params
      params[:city][:suggest_bounds] = JSON.parse(params[:city][:suggest_bounds])
      params.require(:city).permit(:name, :code, :time_zone, :suggest_bounds)
    end
end
