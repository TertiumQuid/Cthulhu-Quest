require 'test_helper'

class Web::CharactersControllerTest < ActionController::TestCase
  def setup
    @user = users(:aleph)
    @character = characters(:thomas_malone)
    @contact = contacts(:aleph_henry_armitage)
  end
  
  test 'show for anonymous' do
    get :show, :id => @character.id
    assert_response :success
    assert_template "web/characters/show"
    assert !assigns(:character).blank?
  end
  
  test 'show' do
    @controller.login!(@user)
    flexmock(@controller).should_receive(:redirect_for_contact).once
    get :show, :id => @character.id
    assert_response :success
    assert_template "web/characters/show"
    assert !assigns(:character).blank?
  end
  
  test 'show and redirect_for_contact' do
    @controller.login!(@user)
    get :show, :id => @contact.character_id
    assert_response :found
    assert_redirected_to web_contact_path( @contact.id )
  end  
  
  test 'character_to_contact_id empty without investigator' do
    assert_nil @controller.send(:character_to_contact_id)
  end
  
  test 'character_to_contact_id empty without id' do
    @controller.login!(@user)
    assert_nil @controller.send(:character_to_contact_id)
  end  
  
  test 'character_to_contact_id' do
    @controller.login!(@user)
    @controller.params[:id] = @contact.character_id
    assert_equal @contact.id, @controller.send(:character_to_contact_id)
  end
  
  test 'routes' do
    assert_routing("/web/characters/1", { :controller => 'web/characters', :action => 'show', :id => '1' })
  end  
end