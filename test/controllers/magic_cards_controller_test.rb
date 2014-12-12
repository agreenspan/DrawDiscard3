require 'test_helper'

class MagicCardsControllerTest < ActionController::TestCase
  test "should get card" do
    get :card
    assert_response :success
  end

end
