require 'test_helper'

class Facebook::CharactersControllerTest < ActionController::TestCase
  def setup
    @user = users(:aleph)
    @character = characters(:henry_armitage)
    init_signed_request
  end
  
  test 'show as anonymous' do
    get :show, :id => @character.id
    assert_response :success
    assert_template "facebook/characters/show"
    assert !assigns(:character).blank?
  end  
  
  test 'show' do
    get :show, :signed_request => @signed_request, :id => @character.id
    assert_response :success
    assert_template "facebook/characters/show"
    assert !assigns(:character).blank?
  end
  
  test 'show with introduction' do
    Contact.destroy_all
    intro = @user.investigator.introductions.new(:character_id => @character.id, :status => 'arranged', :plot => Plot.first)
    intro.save!(:validates => false)
  
    get :show, :signed_request => @signed_request, :id => @character.id
    assert_response :success
    assert_template "facebook/characters/show"
    assert_equal intro, assigns(:introduction)
  end  
  
  test 'show for js' do
    get :show, :signed_request => @signed_request, :id => @character.id, :format => 'js'
    assert_response :success
    assert_js_response
    json = JSON.parse(@response.body)
    assert_equal 'success', json['status']
    assert !json['html'].blank?
  end  
  
  test 'show_html' do
    opts = {:layout => false, :template => "facebook/characters/show.html"}
    flexmock(@controller).should_receive(:render_to_string).with(opts)
    @controller.send(:show_html)
  end  
  
  test 'routes' do
    assert_routing("/facebook/characters/1", { :controller => 'facebook/characters', :action => 'show', :id => '1' })
  end  
end