require 'test_helper'

class VanguardControllerTest < ActionController::TestCase
  test "should get vanguard" do
    get :vanguard
    assert_response :success
  end

  test "should get show" do
    get :show
    assert_response :success
  end

end
