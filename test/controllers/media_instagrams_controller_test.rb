require 'test_helper'

class MediaInstagramsControllerTest < ActionController::TestCase
  setup do
    @media_instagram = media_instagrams(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:media_instagrams)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create media_instagram" do
    assert_difference('MediaInstagram.count') do
      post :create, media_instagram: { comment_count: @media_instagram.comment_count, created_time: @media_instagram.created_time, height: @media_instagram.height, lat: @media_instagram.lat, lng: @media_instagram.lng, location_id: @media_instagram.location_id, location_name: @media_instagram.location_name, media_type: @media_instagram.media_type, tags: @media_instagram.tags, url: @media_instagram.url, width: @media_instagram.width }
    end

    assert_redirected_to media_instagram_path(assigns(:media_instagram))
  end

  test "should show media_instagram" do
    get :show, id: @media_instagram
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @media_instagram
    assert_response :success
  end

  test "should update media_instagram" do
    patch :update, id: @media_instagram, media_instagram: { comment_count: @media_instagram.comment_count, created_time: @media_instagram.created_time, height: @media_instagram.height, lat: @media_instagram.lat, lng: @media_instagram.lng, location_id: @media_instagram.location_id, location_name: @media_instagram.location_name, media_type: @media_instagram.media_type, tags: @media_instagram.tags, url: @media_instagram.url, width: @media_instagram.width }
    assert_redirected_to media_instagram_path(assigns(:media_instagram))
  end

  test "should destroy media_instagram" do
    assert_difference('MediaInstagram.count', -1) do
      delete :destroy, id: @media_instagram
    end

    assert_redirected_to media_instagrams_path
  end
end
