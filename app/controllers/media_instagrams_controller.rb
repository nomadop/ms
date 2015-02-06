class MediaInstagramsController < ApplicationController
  before_action :set_media_instagram, only: [:show, :edit, :update, :destroy]

  def filter_map
    @media_instagrams = MediaInstagram.where("filter_tags LIKE ?", "%#{params[:filter]}%")
  end

  # GET /media_instagrams
  # GET /media_instagrams.json
  def index
    @media_instagrams = MediaInstagram.all
  end

  def display
    if params[:filter]
      @media_instagrams = MediaInstagram.where("filter_tags LIKE ?", "%#{params[:filter]}%")
    else
      @media_instagrams = MediaInstagram.all
    end
    page = params[:page] || 1
    per = params[:per] || 20
    @media_instagrams = @media_instagrams.includes(:detect_results).page(page).per(per)
  end

  # GET /media_instagrams/1
  # GET /media_instagrams/1.json
  def show
  end

  # GET /media_instagrams/new
  def new
    @media_instagram = MediaInstagram.new
  end

  # GET /media_instagrams/1/edit
  def edit
  end

  # POST /media_instagrams
  # POST /media_instagrams.json
  def create
    @media_instagram = MediaInstagram.new(media_instagram_params)

    respond_to do |format|
      if @media_instagram.save
        format.html { redirect_to @media_instagram, notice: 'Media instagram was successfully created.' }
        format.json { render :show, status: :created, location: @media_instagram }
      else
        format.html { render :new }
        format.json { render json: @media_instagram.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /media_instagrams/1
  # PATCH/PUT /media_instagrams/1.json
  def update
    respond_to do |format|
      if @media_instagram.update(media_instagram_params)
        format.html { redirect_to @media_instagram, notice: 'Media instagram was successfully updated.' }
        format.json { render :show, status: :ok, location: @media_instagram }
      else
        format.html { render :edit }
        format.json { render json: @media_instagram.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /media_instagrams/1
  # DELETE /media_instagrams/1.json
  def destroy
    @media_instagram.destroy
    respond_to do |format|
      format.html { redirect_to media_instagrams_url, notice: 'Media instagram was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_media_instagram
      @media_instagram = MediaInstagram.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def media_instagram_params
      params.require(:media_instagram).permit(:url, :media_type, :tags, :comment_count, :created_time, :location_id, :location_name, :lat, :lng, :width, :height)
    end
end
