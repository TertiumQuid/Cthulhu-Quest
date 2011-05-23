require 'test_helper'

class UserTest < ActiveSupport::TestCase
  def setup
    @user = users(:aleph)
    @user_hash = { 
      :id => '1234567890', 
      :first_name => 'tester', 
      :name => 'tester example', 
      :email => 'hash@example.com',
      :friends => {:data => [{:name => "First Friend", :id => '001'}, {:name => "Second Friend", :id => '002'}]}
    }
  end
  
  test 'find_or_create_from_access with existing user' do
    access = flexmock(:token => @user.facebook_token, :get => @user_hash.to_json)
    assert_no_difference 'User.count', "no user should be created when token exists" do
      user = User.find_or_create_from_access( access )
      assert_equal @user, user, "found user should match on facebook_token"
    end
  end
  
  test 'find_or_create_from_access with new user' do
    access = flexmock(:token => 'abc123xyz890', :get => @user_hash.to_json)
    assert_difference 'User.count', +1, "new user should be created when no token exists" do
      user = User.find_or_create_from_access( access )
      assert_equal @user_hash[:id], user.facebook_id, "new user should have matching facebook_id"
      assert_equal @user_hash[:first_name], user.name, "new user should have matching name"
      assert_equal @user_hash[:name], user.full_name, "new user should have matching full_name"
      assert_equal @user_hash[:email], user.email, "new user should have matching email"
      assert_equal '001,002', user.facebook_friend_ids, "new user should have comma separated friend id list"
    end
  end
  
  test 'facebook_photo' do
    expected = "http://graph.facebook.com/#{@user.facebook_id}/picture?type=square"
    assert_equal expected, @user.facebook_photo
  end
  
  test 'friends' do
    friends = @user.friends
    assert !friends.blank?, "facebook friends required"
    
    friends.each do |f|
      assert @user.facebook_friend_ids.split(',').include?(f.facebook_id), "only facebook friends should match"
    end
    
    [nil,'12,34,56'].each do |val|
      assert @user.update_attribute(:facebook_friend_ids, val)
      assert_equal [], @user.friends, "facebook friends should return empty array with no friend results"
    end
  end
  
  test 'unallied_friends' do
    mocked = User.where(["facebook_id IN (?)", @user.facebook_friend_ids.split(',') ])
    flexmock(@user).should_receive(:friends).and_return(mocked).once
    allies(:aleph_beth).destroy
    
    friends = @user.unallied_friends
    assert !friends.blank?, "facebook friends required"
    friends.each do |f|
      assert @user.facebook_friend_ids.split(',').include?(f.facebook_id), "only facebook friends should match"
      assert !@user.investigator.allies.map(&:ally_id).include?(f.investigator_id), "no allies should match"
    end
    
  end
  
  test 'unallied_friends without investigator' do  
    mocked = User.where(["facebook_id IN (?)", @user.facebook_friend_ids.split(',') ])
    allies(:aleph_beth).destroy
    
    friends = @user.unallied_friends
    @user.update_attribute(:investigator_id, nil)
    assert_equal friends.size, @user.unallied_friends.size
  end
  
  test 'set_password' do
    user = User.create
    pw = user.password
    assert_not_nil pw
    assert_equal 32, pw.size
    
    user.send(:set_password)
    assert_equal pw, user.password
  end
  
  test 'set_nonce!' do
    assert_nil @user.nonce
    assert_nil @user.last_login_at
    
    @user.set_nonce!
    assert_equal 128, @user.nonce.size
    
    old = @user.nonce
    @user.set_nonce!
    assert_not_equal old, @user.nonce
  end
  
  test 'friends?' do
    friend = users(:gimel)
    @user.update_attribute(:facebook_friend_ids, users(:beth).facebook_friend_ids)
    assert_equal false, @user.friends?( friend )
    
    @user.update_attribute(:facebook_friend_ids, friend.facebook_id)
    assert_equal true, @user.friends?( friend )
    
    @user.update_attribute(:facebook_friend_ids, nil)
    assert_equal false, @user.friends?( friend )
  end
  
  test 'update_facebook_friends_from_access' do
    json = {:friends => {:data => [{:id => '1234567890'},{:id => '0987654321'}] }}.to_json
    mock = flexmock(:get => json)
    ts = Time.now
    flexmock(Time).should_receive(:now).and_return(ts)
    @user.update_attribute(:last_facebook_update_at, nil)
    
    assert_equal true, @user.update_facebook_friends_from_access(mock)
    assert_equal "1234567890,0987654321", @user.reload.facebook_friend_ids
    assert_equal ts.to_i, @user.last_facebook_update_at.to_i
    
    assert_nil @user.update_facebook_friends_from_access(mock)
  end

  test 'update_facebook_friends_from_access with socket error' do
    ts = Time.now
    flexmock(Time).should_receive(:now).and_return(ts)
    mock = flexmock()
    mock.should_receive(:get).and_raise(SocketError)
    @user.update_attribute(:last_facebook_update_at, nil)

    assert_no_difference "@user.facebook_friend_ids.split(',').size" do
      @user.update_facebook_friends_from_access(mock)
    end
  end

  test 'update_facebook_friends_from_access with http error' do
    ts = Time.now
    flexmock(Time).should_receive(:now).and_return(ts)
    mock = flexmock()
    mock.should_receive(:get).and_raise(OAuth2::HTTPError)
    @user.update_attribute(:last_facebook_update_at, nil)

    assert_no_difference "@user.facebook_friend_ids.split(',').size" do
      @user.update_facebook_friends_from_access(mock)
    end
  end

  
  test 'set_last_login_at' do
    timestamp = Time.now
    flexmock(Time).should_receive(:now).and_return(timestamp)
    @user.send(:set_last_login_at)
    assert_equal timestamp, @user.last_login_at
  end
  
  test 'set_last_login_at ignored' do  
    timestamp = Time.now - 4.minutes + 50.seconds
    @user.last_login_at = timestamp
    @user.set_last_login_at
    assert_equal timestamp.to_i, @user.last_login_at.to_i
  end  
end