require 'test_helper'

class IntrigueTest < ActiveSupport::TestCase
  def setup
    @investigator = investigators(:aleph_pi)
    @ally = investigators(:beth_pi)
    @contact = characters(:thomas_malone)
    @intrigue = intrigues(:grandfathers_journal_1)
  end
  
  test 'threshold with investigator' do
    threshold = @intrigue.send(:threshold, @investigator )
    skill = @investigator.research
    expected = Intrigue::THRESHOLD_BASE - @intrigue.difficulty + skill
    assert_equal expected, threshold
  end
  
  test 'threshold with investigator and ally' do  
    threshold = @intrigue.send(:threshold, @investigator, @ally )
    skill = (@investigator.research + @ally.research)
    expected = Intrigue::THRESHOLD_BASE - @intrigue.difficulty + skill
    assert_equal expected, threshold
  end
  
  test 'threshold with investigator and ally and contact' do  
    threshold = @intrigue.send(:threshold, @investigator, @ally, @contact )
    skill = (@investigator.research + @ally.research + @contact.research)
    expected = Intrigue::THRESHOLD_BASE - @intrigue.difficulty + skill
    assert_equal expected, threshold
  end  
  
  test 'threshold with unskilled investigator' do  
    stats(:aleph_research).update_attribute(:skill_level, 0)
    expected = Intrigue::THRESHOLD_BASE - @intrigue.difficulty
    assert_equal expected, @intrigue.send(:threshold, @investigator )
  end
  
  test 'opposition_score' do  
    flexmock(@intrigue).should_receive(:skill_level).and_return( @investigator.research ).once
    opposition = @intrigue.send(:opposition_score, @investigator )
    skill = @investigator.research
    assert_equal skill, opposition
  end
  
  test 'opposition_score with ally' do  
    flexmock(@intrigue).should_receive(:skill_level).and_return( @investigator.research ).times(3)
    opposition = @intrigue.send(:opposition_score, @investigator, @ally )
    skill = @investigator.research + @intrigue.send(:skill_level, @ally )
    assert_equal skill, opposition
  end
  
  test 'opposition_score with contact' do  
    flexmock(@intrigue).should_receive(:skill_level).and_return( @investigator.research ).times(3)
    opposition = @intrigue.send(:opposition_score, @investigator, nil, @contact  )
    skill = @investigator.research + @intrigue.send(:skill_level, @contact )
    assert_equal skill, opposition
  end  
  
  test 'skill_level' do
    flexmock(@intrigue).should_receive(:insanity_penalty).once.and_return(0)
    flexmock(@intrigue).should_receive(:wound_penalty).once.and_return(0)
    flexmock(@intrigue).should_receive(:effect_bonus).once.and_return(0)
    
    skill = @intrigue.send(:skill_level, @investigator)
    assert_equal @investigator.send(:research), skill
  end
  
  test 'skill_level with character' do
    flexmock(@intrigue).should_receive(:wound_penalty).times(0)
    flexmock(@intrigue).should_receive(:effect_bonus).times(0)
    
    skill = @intrigue.send(:skill_level, @contact)
    assert_equal @contact.send(:research), skill
  end  
  
  test 'skill_level with wounds' do
    flexmock(@intrigue).should_receive(:wound_penalty).once.and_return(1)
    flexmock(@intrigue).should_receive(:effect_bonus).once.and_return(0)
    
    skill = @intrigue.send(:skill_level, @investigator)
    assert_equal @investigator.send(:research) - 1, skill    
  end
  
  test 'skill_level with insanity' do
    flexmock(@intrigue).should_receive(:insanity_penalty).once.and_return(1)
    flexmock(@intrigue).should_receive(:wound_penalty).once.and_return(0)
    flexmock(@intrigue).should_receive(:effect_bonus).once.and_return(0)
    
    skill = @intrigue.send(:skill_level, @investigator)
    assert_equal @investigator.send(:research) - 1, skill
  end  
  
  test 'skill_level with spell' do
    flexmock(@intrigue).should_receive(:wound_penalty).once.and_return(0)
    flexmock(@intrigue).should_receive(:effect_bonus).once.and_return(1)
    
    skill = @intrigue.send(:skill_level, @investigator)
    assert_equal @investigator.send(:research) + 1, skill    
  end  
  
  test 'skill_level minimum' do
    flexmock(@intrigue).should_receive(:wound_penalty).once.and_return(10)
    flexmock(@intrigue).should_receive(:effect_bonus).once.and_return(-10)
    
    skill = @intrigue.send(:skill_level, @investigator)
    assert_equal 0, skill    
  end
  
  test 'wound_penalty' do
    @investigator.wounds = 10
    penalty = @intrigue.wound_penalty(@investigator)
    assert_equal 10, penalty
  end
  
  test 'insanity_penalty' do
    assert_equal 0, @intrigue.insanity_penalty(@investigator)
    
    insanity = insanities(:dementia)
    assert_equal insanity.skill_id, @intrigue.challenge_id
    @investigator.psychoses.create!(:insanity => insanity)
    assert_equal 3, @intrigue.insanity_penalty(@investigator)
  end
  
  test 'effect_bonus' do
    effect = effects(:trance_state_of_daoloth_enhance_skill)
    effect.target = @intrigue.challenge
    effect.save
    @investigator.effections.create(:effect => effect)
    
    assert_equal effect.power, @intrigue.effect_bonus(@investigator)
  end
  
  test 'effect_bonus expired' do
    effect = effects(:trance_state_of_daoloth_enhance_skill)
    effect.target = @intrigue.challenge
    effect.save
    
    effection = @investigator.effections.create(:effect => effect)
    effection.update_attribute(:begins_at, Time.now - 8.hours)
    effection.update_attribute(:ends_at, Time.now - 1.minute)    
    
    assert_equal 0, @intrigue.effect_bonus(@investigator)
  end  
  
  test 'effect_bonus empty' do
    assert_equal 0, @intrigue.effect_bonus(nil)
    assert_equal 0, @intrigue.effect_bonus(@investigator)
  end
end