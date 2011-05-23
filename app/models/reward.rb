class Reward < ActiveRecord::Base
  TYPES = ['funds','item','experience','grimoire','plot','introduction']
  
  belongs_to :plot
  
  validates :plot_id, :numericality => true  
  validates :reward_id, :numericality => true  
  validates :reward_name, :length => { :minimum => 1, :maximum => 256 }
  validates :reward_type, :length => { :minimum => 1, :maximum => 256 }, :inclusion => { :in => TYPES }
  
  def award!(investigator)
    case reward_type
      when 'funds'
        award_funds_to(investigator)
      when 'item'
        award_item_to(investigator) 
      when 'grimoire'
        award_grimoire_to(investigator)        
      when 'experience'
        award_experience_to(investigator)
      when 'plot'
        award_plot_to(investigator)
      when 'introduction'
        award_introduction_to(investigator)
    end    
  end
  
private

  def award_funds_to(investigator)
    investigator.funds = investigator.funds + reward_id
  end  
  
  def award_item_to(investigator)
    investigator.possessions.build(:item_id => reward_id, :origin => 'reward')
  end
  
  def award_experience_to(investigator)
    investigator.award_experience!( reward_id, :save => false )
  end
  
  def award_grimoire_to(investigator)
    investigator.spellbooks.build(:grimoire_id => reward_id) unless investigator.grimoire_ids.include?(reward_id)
  end
  
  def award_introduction_to(investigator)
    investigator.introductions.build(:investigator_id => investigator.id, :plot_id => plot.id) unless investigator.has_contact?(reward_id)
  end  
  
  def award_plot_to(investigator)
    investigator.casebook.build(:plot_id => reward_id)
  end
end