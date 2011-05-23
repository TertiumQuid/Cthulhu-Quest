require 'test_helper'

class Facebook::SpellbooksControllerTest < ActionController::TestCase
  def setup
    @user = users(:aleph)
    @investigator = investigators(:aleph_pi)
    @spellbook = spellbooks(:aleph_book_of_dzyan)
    init_signed_request
  end
  
  test 'index' do
    get :index, :signed_request => @signed_request
    assert_response :success
    assert_template "facebook/spellbooks/index"
    assert !assigns(:spellbooks).blank?
    assert !assigns(:spells).blank?
  end
  
  test 'index with casting' do
    spell = spells(:sway_of_the_adept)
    casting = @user.investigator.castings.create!(:spell_id => spell.id)
    
    get :index, :signed_request => @signed_request
    assert_response :success
    assert_template "facebook/spellbooks/index"
    assert !assigns(:casting).blank?
  end    
  
  test 'index with effections' do  
    spell = spells(:sway_of_the_adept)
    casting = @user.investigator.castings.create!(:spell_id => spell.id)
    effect = spell.effects.last
    effect.effections.update_all(:begins_at => Time.now - 1.minute, :ends_at => Time.now + 10.minutes)
    
    get :index, :signed_request => @signed_request
    assert_response :success
    assert_template "facebook/spellbooks/index"
    assert !assigns(:effections).blank?
  end
  
  test 'index for js' do
    get :index, :signed_request => @signed_request, :format => 'js'
    assert_response :success
    assert_html_response
    assert_template "facebook/spellbooks/index"
  end  
  
  test 'update' do
    assert_difference ['@investigator.spellbooks.read.count'], +1 do
      assert_difference ['@investigator.spellbooks.unread.count'], -1 do
        assert_difference ['@investigator.madness'], +@spellbook.grimoire.madness_cost do
          put :update, :id => @spellbook.id, :signed_request => @signed_request
          assert_response :found
          assert !flash[:notice].blank?
          @investigator.reload
        end
      end
    end  
    assert_redirected_to facebook_spellbooks_path  
  end  
  
  test 'update and madness' do
    @investigator.update_attribute(:madness, @investigator.maximum_madness - 1)
    assert_difference ['@investigator.madness'], -@investigator.madness do
      put :update, :id => @spellbook.id, :signed_request => @signed_request
      assert_response :found
      assert !flash[:notice].blank?
      @investigator.reload
    end
    assert_redirected_to facebook_spellbooks_path
  end  
  
  test 'update for js' do
    put :update, :id => @spellbook.id, :signed_request => @signed_request, :format => 'js'
    assert_response :success
    json = JSON.parse(@response.body)
    assert_equal 'success', json['status']
    assert !json['title'].blank?
    assert !json['message'].blank?
    assert !json['html'].blank?
  end  
  
  test 'return_path' do
    assert_equal facebook_spellbooks_path, @controller.send(:return_path)
  end  
  
  test 'success_message' do
    @controller.instance_variable_set( '@spellbook', @spellbook )
    expected = "A scholar labors in the pages like a ploughman in the field. Your readings have brought enlightment and you complete #{@spellbook.name} with an understanding as great as any sage, yet oblivious to the albatross of (#{@spellbook.grimoire.madness_cost}) madness."
    assert_equal expected, @controller.send(:success_message)
  end  
  
  test 'failure_message' do
    @controller.instance_variable_set( '@spellbook', @spellbook )
    expected = "Heedless of your fraying mind, you read too obsessively to ignore the terrible profundities in the pages. You complete #{@spellbook.name}, but at the cost of (#{@spellbook.grimoire.madness_cost}) madness and an insanity."
    assert_equal expected, @controller.send(:failure_message)
  end  
  
  test 'sanity_status' do
    assert_nil @controller.send(:sanity_status)
    
    @controller.instance_variable_set( '@investigator', @user.investigator )
    assert_nil @controller.send(:sanity_status)
    
    @controller.instance_variable_set( '@current_investigator', @user.investigator )
    assert_equal @user.investigator.madness_status, @controller.send(:sanity_status)
  end  
  
  test 'require_user' do
    get :index
    assert_user_required
    
    put :update, :id => 1    
    assert_user_required
  end

  test 'require_investigator' do
    assert @user.investigator.destroy
    
    get :index, :signed_request => @signed_request
    assert_investigator_required
    
    put :update, :signed_request => @signed_request, :id => 1
    assert_investigator_required    
  end  
  
  test 'routes' do
    assert_routing("/facebook/spellbooks", { :controller => 'facebook/spellbooks', :action => 'index' })
    assert_routing({:method => 'put', :path => "/facebook/spellbooks/1"}, 
                   {:controller => 'facebook/spellbooks', :action => 'update', :id => '1' })    
  end  
end