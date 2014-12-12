require 'test_helper'

class TransactionsControllerTest < ActionController::TestCase
  test "should get transaction" do
    get :transaction
    assert_response :success
  end

  test "should get cancel" do
    get :cancel
    assert_response :success
  end

end
