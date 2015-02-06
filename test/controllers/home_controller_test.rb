require 'test_helper'

class HomeControllerTest < ActionController::TestCase
  test "should get test" do
    get :test
    assert_response :success
  end

end
