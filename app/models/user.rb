class User < ActiveRecord::Base
  include Facebook::Graph
  
  has_one :investigator, :dependent => :destroy
  has_one :character, :dependent => :destroy
  has_many :sessions, :dependent => :destroy
  
  before_validation :set_password, :on => :create
  
  validates :email, :length => { :minimum => 5, :maximum => 256 }
  
  scope :investigating, where("users.investigator_id IS NOT NULL")
  scope :investigator, includes(:investigator).where("users.investigator_id IS NOT NULL")
  
  def friends
    facebook_friend_ids ? User.where(["facebook_id IN (?)", facebook_friend_ids.split(',') ]) : []
  end
  
  def unallied_friends
    investigator_id.blank? ? friends : friends.where("investigator_id NOT IN (SELECT ally_id FROM allies WHERE investigator_id = #{investigator_id})")
  end
  
  class << self
    def find_or_create_from_access(access)
      user = find_or_initialize_by_facebook_token( access.token )
      fb = JSON.parse( access.get('/me?fields=id,first_name,name,email,location,gender,friends,birthday') )
      Rails.logger.info fb.inspect
      
      user = find_by_facebook_id( fb['id'] ) || user
      user.facebook_token = access.token
      user.facebook_id = fb['id']
      user.name = fb['first_name']
      user.full_name = fb['name']
      user.email = fb['email']
      user.facebook_friend_ids = fb['friends']['data'].map{|f| f['id'] }.join(",")
      user.save
        
      return user
    end
  end
  
  def facebook_photo(size='square')
    "http://graph.facebook.com/#{facebook_id}/picture?type=#{size}"
  end
  
  def friends?(user)
    facebook_friend_ids ? facebook_friend_ids.split(",").include?( user.facebook_id.to_s ) : false
  end
    
  def set_nonce!(opts={})
    self.nonce = SecureRandom.hex(128)[1..128]
    save if opts[:save] == true
  end
  
  def set_last_login_at(opts={})
    return unless last_login_at.blank? || Time.now - 5.minutes > last_login_at
    
    self.last_login_at = Time.now
    save if opts[:save] == true
  end
  
  def update_facebook_friends_from_access(access)
    return unless last_facebook_update_at.blank? || Time.now - 6.hours > last_facebook_update_at
    
    fb = JSON.parse( access.get('/me?fields=friends') )  
    self.facebook_friend_ids = fb['friends']['data'].map{|f| f['id'] }.join(",")
    self.last_facebook_update_at = Time.now
    save
  rescue OAuth2::HTTPError => e
    update_attribute(:last_facebook_update_at, Time.now)
  rescue SocketError => e        
    update_attribute(:last_facebook_update_at, Time.now)
  end
  
private  
  
  def set_password
    self.password ||= SecureRandom.hex(32)[1..32]
  end  
end