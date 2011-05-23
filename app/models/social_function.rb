class SocialFunction < ActiveRecord::Base
  TIMEFRAME = 4
  has_many :socials, :dependent => :destroy
  
  def reward_investigator(investigator, score)
    case kind
      when 'moxie'
        reward_moxie(investigator, score)
        return "gained #{score} moxie"
      when 'item'
        item = reward_item(investigator, score)
        return "gained a #{item.item_name.downcase}"
      when 'sanity'
        reward_sanity(investigator, score)
        return "recovered #{score} sanity"
      when 'health'
        reward_health(investigator, score)
        return "recovered #{score} wounds"
    end    
  end
  
  private
  
  def reward_moxie(investigator, score)
    investigator.update_attribute(:moxie, investigator.moxie + score)
  end
  
  def reward_item(investigator, score)
    scoped = Item.where("price <= #{item_price_from_score(score)}").dry_goods
    number = [rand( scoped.count ) - 1, 0].max
    item = scoped.limit(1).offset(number).first
    investigator.possessions.create(:item => item, :origin => 'reward') if item
  end
  
  def reward_sanity(investigator, score)
    investigator.update_attribute(:madness, [investigator.madness - score, 0].max)
  end  
  
  def reward_health(investigator, score)
    investigator.update_attribute(:wounds, [investigator.wounds - (score * 2), 0].max)
  end 
  
  def item_price_from_score(score)
    (score == 0 ? 5 : (score == 1 ? 10 : (score == 2 ? 50 : (score == 3 ? 100 : 0))))
  end 
end