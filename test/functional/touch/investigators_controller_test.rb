require 'test_helper'

class Touch::InvestigatorsControllerTest < ActionController::TestCase
  def setup
    @user = users(:aleph)
    @medical = items(:first_aid_kit)
    @investigator = investigators(:aleph_pi)
  end
end