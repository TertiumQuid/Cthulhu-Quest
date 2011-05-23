class Gift < ActiveRecord::Base
  TYPES = ['item','weapon','funds']
  
  belongs_to :investigator
  belongs_to :sender, :class_name => 'Investigator'

  validates :investigator_id, :numericality => {:message => 'is missing'}
  validates :sender_id, :numericality => {:message => 'is missing'}  
  validates :gift_id, :numericality => {:message => 'is missing'}
  validates :gift_type, :inclusion => { :in => TYPES, :message => 'is not allowed' }
  validates :gift_name, :length => { :minimum => 1, :maximum => 256, :message => 'is missing' }
  validate  :validates_ownership
  
  before_create :set_sender_name
  after_create  :send_gift
  after_create  :log_gift  
  
  def gifting=(value)
    @gifting = value
    if funds_value?(value)
      self.gift_id = value
      self.gift_name = "£#{value}"
      self.gift_type = 'funds'
    elsif value && possession = sender.possessions.where( ["item_name LIKE ?", value] ).first
      self.gift_id = possession.item_id
      self.gift_name = possession.item_name
      self.gift_type = 'item'
    elsif value && armament = sender.armaments.where( ["weapon_name LIKE ?", value] ).first
      self.gift_id = armament.weapon_id
      self.gift_name = armament.weapon_name
      self.gift_type = 'weapon'      
    end
  end
  
  def gifting
    if gift_type == 'funds'
      @gifting = gift_id.to_i
    elsif gift_type == 'item'
      @gifting = Item.find( gift_id )
    elsif gift_type == 'weapon'
      @gifting = Weapon.find( gift_id )
    else
      @gifting
    end
  end
  
  def funds?
    gift_type == 'funds'
  end
  
  def item?
    gift_type == 'item'
  end
  
  def weapon?
    gift_type == 'weapon'
  end
  
private

  def set_sender_name
    self.sender_name = sender.name if sender
  end

  def funds_value?(value)
    !value.blank? && (value.is_a?(Integer) || (value.is_a?(String) && !(value =~ /^\d+$/).nil?) )
  end
  
  def validates_ownership
    if funds?
      validate_funds
    elsif item?
      validate_item
    elsif weapon?
      validate_weapon
    end
  end
  
  def validate_funds
    return unless funds? && errors[:base].blank?
    errors[:base] << "insufficient funds at your disposal for such a generous gift" if gifting > sender.funds
  end
  
  def validate_item
    return unless item? && errors[:base].blank? && !sender.possessions.where( :item_id => gift_id ).exists?
    errors[:base] << "you don't possess an item by that name" 
  end
  
  def validate_weapon
    return unless weapon? && errors[:base].blank? && !sender.armaments.where( :weapon_id => gift_id ).exists?
    errors[:base] << "you don't possess a weapon by that name" 
  end  
  
  def send_gift
    if funds?
      send_funds
    elsif item?
      send_item
    elsif weapon?
      send_weapon
    end
  end
  
  def send_funds
    investigator.update_attribute(:funds, investigator.funds + gifting)
    sender.update_attribute(:funds, sender.funds - gifting)
  end
  
  def send_item
    if item = sender.possessions.where( :item_id => gift_id ).first
      investigator.possessions.create(:item_id => gift_id, :origin => 'gift')
      item.destroy
    end
  end
  
  def send_weapon
    if weapon = sender.armaments.where( :weapon_id => gift_id ).first
      investigator.armaments.create(:weapon_id => gift_id, :origin => 'gift')
      weapon.destroy
      sender.update_attribute(:armed_id, nil) if sender.armed_id == weapon.id
    end
  end  
  
  def log_gift
    subject = gifting
    if funds?
      InvestigatorActivity.log investigator, 'gifted.funds', :actor => sender, :scope => gift_id
      InvestigatorActivity.log sender, 'gift.funds', :object => investigator, :scope => gift_id
    elsif item?
      InvestigatorActivity.log investigator, 'gifted.item', :actor => sender, :subject => subject
      InvestigatorActivity.log sender, 'gift.item', :object => investigator, :subject => subject
    elsif weapon?      
      InvestigatorActivity.log investigator, 'gifted.weapon', :actor => sender, :subject => subject
      InvestigatorActivity.log sender, 'gift.weapon', :object => investigator, :subject => subject
    end
  end
end