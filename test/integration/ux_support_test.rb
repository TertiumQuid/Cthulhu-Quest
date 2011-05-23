require 'test_helper'

class UxSupportTest < ActionController::IntegrationTest
  def setup
    @user = users(:aleph)
    get '/' # indirectly intialize application_controller for simulating basic controller environment
  end
  
  test 'json_response_hash' do
    res = @controller.json_response_hash
    [:status,:html,:json,:title,:message,:to].each do |k|
      assert res.has_key?(k)
      assert_nil res[k]
    end
  end
  
  test 'render_json_response' do
    hash = { :json => @controller.json_response_hash.merge( :status => :success ).merge(:message => 'test') }
    
    flexmock(@controller).should_receive(:render).with(hash)
    @controller.render_json_response(:success, :message => 'test')
  end
  
  test 'render_and_respond for html render' do
    flexmock(@controller).should_receive(:render).once
    @controller.render_and_respond :success, :message => 'test'
    assert_equal 'test', @controller.flash[:notice]
  end
  
  test 'render_and_respond for html redirect' do
    flexmock(@controller).should_receive(:redirect_to).with(facebook_root_path).once
    @controller.render_and_respond :success, :message => 'test', :to => facebook_root_path
    assert_equal 'test', @controller.flash[:notice]
  end  
  
  test 'render_and_respond for html error or failure' do
    flexmock(@controller).should_receive(:render)
    
    @controller.render_and_respond :error, :message => 'test'
    assert_equal 'test', @controller.flash[:error]
    
    @controller.render_and_respond :failure, :message => 'test'
    assert_equal 'test', @controller.flash[:error]    
  end  
  
  test 'render_and_respond for js render_to_string' do
    get '/', :format => 'js'
    opts = {:layout => false, :content_type => 'text/html'}
    flexmock(@controller).should_receive(:render_to_string).with(opts).once
    @controller.render_and_respond :success
  end  
  
  test 'render_and_respond for js render_json_response' do
    get '/', :format => 'js'
    opts = {:message => 'test'}
    flexmock(@controller).should_receive(:render_json_response).with( :success, opts.with_indifferent_access ).once
    @controller.render_and_respond :success, opts
  end  

  test 'fb_url' do
    assert_equal "http://apps.facebook.com/cthulhuquest", @controller.fb_url(facebook_root_path,true)
    assert_equal "http://apps.facebook.com/cthulhuquest/investigator/profile", @controller.fb_url(edit_facebook_investigator_path,true)
  end
end