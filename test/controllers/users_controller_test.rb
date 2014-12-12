require 'test_helper'

class UsersControllerTest < ActionController::TestCase
  test "should get confirmation" do
    get :confirmation
    assert_response :success
  end

  test "should get change_password" do
    get :change_password
    assert_response :success
  end

  test "should get collection" do
    get :collection
    assert_response :success
  end

  test "should get transactions" do
    get :transactions
    assert_response :success
  end

  test "should get mtgo_accounts" do
    get :mtgo_accounts
    assert_response :success
  end

  test "should get mtgo_codes" do
    get :mtgo_codes
    assert_response :success
  end

end
