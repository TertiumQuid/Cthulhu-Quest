require 'test_helper'

class Facebook::CastingsControllerTest < ActionController::TestCase
  def setup
    @user = users(:aleph)
    @investigator = investigators(:aleph_pi)
    @spell = spells(:sway_of_the_adept)
    init_signed_request
  end
  
  test 'new' do
    get :new, :spell_id => @spell.id, :signed_request => @signed_request
    assert_response :success
    assert_template "facebook/castings/new"
  end  
  
  test 'new for js' do
    get :new, :spell_id => @spell.id, :signed_request => @signed_request, :format => 'js'
    assert_response :success
    assert_js_response
    json = JSON.parse(@response.body)
    assert_equal 'success', json['status']
    assert !json['html'].blank?
    assert !json['title'].blank?
  end  
  
  test 'create' do
    assert_difference '@investigator.effections.count', +@spell.effects.count do
      assert_difference ['Casting.count','@investigator.castings.count'], +1 do      
        post :create, :spell_id => @spell.id, :signed_request => @signed_request
        assert_response :found
        assert !assigns(:spell).blank?
        assert !assigns(:casting).blank?
        assert !flash[:notice].blank?
        assert_redirected_to facebook_spellbooks_path
      end
    end
  end  
  
  test 'create for js' do
    assert_difference '@investigator.effections.count', +@spell.effects.count do
      assert_difference ['Casting.count','@investigator.castings.count'], +1 do      
        post :create, :spell_id => @spell.id, :signed_request => @signed_request, :format => 'js'
        assert_response :success
        assert_js_response
        json = JSON.parse(@response.body)
        assert_equal 'success', json['status']
        assert !json['message'].blank?
        assert !json['title'].blank?
      end
    end
  end  
  
  test 'return_path' do
    assert_equal facebook_spellbooks_path, @controller.send(:return_path)
  end  
  
  test 'success_message' do
    expected = "You have begun the demanding rituals for casting #{@spell.name}, which will take 1 hour to complete, after which you'll receive #{@spell.effect}."    
    @controller.instance_variable_set( '@spell', @spell )
    assert_equal expected, @controller.send(:success_message)
  end
  
  test 'failure_message' do
    @casting = Casting.new
    @casting.errors[:base] << 'test1'
    @casting.errors[:base] << 'test2'
    @controller.instance_variable_set( '@casting', @casting )
    assert_equal 'test1, test2', @controller.send(:failure_message)
  end  
  
  test 'require_user' do
    get :new, :spell_id => 1
    assert_user_required
    
    post :create, :spell_id => 1
    assert_user_required    
  end

  test 'require_investigator' do
    assert @user.investigator.destroy
    
    get :new, :spell_id => 1, :signed_request => @signed_request
    assert_investigator_required 
    
    post :create, :spell_id => 1, :signed_request => @signed_request
    assert_investigator_required       
  end  
  
  test 'new_html' do
    opts = {:layout => false, :template => "facebook/castings/new.html"}
    flexmock(@controller).should_receive(:render_to_string).with(opts)
    @controller.send(:new_html)
  end  
  
  test 'routes' do
    assert_routing("/facebook/spells/1/castings/new", { :controller => 'facebook/castings', :action => 'new', :spell_id => '1' })
    assert_routing({:method => 'post', :path => "/facebook/spells/1/castings"}, 
                   {:controller => 'facebook/castings', :action => 'create', :spell_id => "1" })    
  end
end