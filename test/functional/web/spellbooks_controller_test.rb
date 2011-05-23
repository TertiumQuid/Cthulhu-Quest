require 'test_helper'

class Web::SpellbooksControllerTest < ActionController::TestCase
  def setup
    @user = users(:aleph)
    @investigator = investigators(:aleph_pi)
    @spellbook = spellbooks(:aleph_book_of_dzyan)
  end

  test 'index without spellbooks' do
    @investigator.spellbooks.destroy_all
    @controller.login!(@user)
  
    get :index
    assert_response :success
    assert_template "web/spellbooks/index"
    assert assigns(:spellbooks).blank?
    assert assigns(:read_spellbooks).blank?
    assert assigns(:unread_spellbooks).blank?
  end
  
  test 'index' do
    @controller.login!(@user)
  
    get :index
    assert_response :success
    assert_template "web/spellbooks/index"
    assert !assigns(:spellbooks).blank?
    assert !assigns(:read_spellbooks).blank?
    assert !assigns(:unread_spellbooks).blank?
    assert !assigns(:spells).blank?
    
    assigns(:unread_spellbooks).each do |spellbook|
      assert_tag :tag => "a", :attributes => { :href => web_spellbook_path(spellbook), 'data-method'=> "put" }
    end
  end
  
  test 'index with casting' do  
    spell = spells(:sway_of_the_adept)
    casting = @investigator.castings.create!(:spell => spell)
    casting.update_attribute(:ended_at, Time.now + 1.day)
    casting.update_attribute(:completed_at, Time.now - 10.minutes)
    @controller.login!(@user)
    
    get :index
    assert_response :success
    assert_template "web/spellbooks/index"
    assert !assigns(:castings).blank?
  end
  
  test 'index while spellcasting' do  
    spell = spells(:sway_of_the_adept)
    casting = @investigator.castings.create!(:spell => spell)
    @controller.login!(@user)
    
    get :index
    assert_response :success
    assert_template "web/spellbooks/index"
    assert assigns(:castings).blank?
  end  
  
  test 'update' do
    @controller.login!(@user)
    
    assert_difference ['@investigator.spellbooks.read.count'], +1 do
      assert_difference ['@investigator.spellbooks.unread.count'], -1 do
        assert_difference ['@investigator.madness'], +@spellbook.grimoire.madness_cost do
          put :update, :id => @spellbook.id
          assert !flash[:notice].blank?
          @investigator.reload
        end
      end
    end  
    assert_redirected_to web_spellbooks_path  
  end
  
  test 'update and madness' do
    @investigator.update_attribute(:madness, @investigator.maximum_madness - 1)
    @controller.login!(@user)
    
    assert_difference ['@investigator.madness'], -@investigator.madness do
      put :update, :id => @spellbook.id
      assert !flash[:notice].blank?
      @investigator.reload
    end  
    assert_redirected_to web_spellbooks_path    
  end
  
  test 'require_user' do
    get :index
    assert_user_required
  end
  
  test 'require_investigator' do
    assert @user.investigator.destroy, "nil investigator required"
    @controller.login!(@user)
    
    get :index
    assert_investigator_required
  end  

  test 'routes' do
    assert_routing("/web/spellbooks", { :controller => 'web/spellbooks', :action => 'index' })
  end  
end