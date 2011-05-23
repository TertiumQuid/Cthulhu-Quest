require 'test_helper'

class PsychosisTest < ActiveSupport::TestCase
  def setup
    @investigator = investigators(:aleph_pi)
    @insanity = insanities(:nightmares)
    @psychosis = @investigator.psychoses.new(:severity => 1)
  end
  
  test 'insanities_for' do
    assert_equal [], Psychosis.insanities_for(nil)
    
    insanities = Psychosis.insanities_for(@investigator)
    assert_equal Insanity.count, insanities.count
    
    @investigator.psychoses.create!(:insanity => @insanity)
    insanities = Psychosis.insanities_for(@investigator)
    assert_equal Insanity.count - 1, insanities.count
    assert !insanities.include?( @investigator.insanities.first )
  end
  
  test 'set_name' do
    psychosis = @investigator.psychoses.create(:insanity => @insanity)
    assert_equal @insanity.name, psychosis.name
  end
  
  test 'default severity' do
    psychosis = @investigator.psychoses.create!(:insanity => @insanity)
    assert_equal 1, psychosis.severity
  end
  
  test 'award! with new' do
    @investigator.psychoses.destroy_all
    assert_difference '@investigator.psychoses.count', +1 do
      assert_equal true, Psychosis.award!(@investigator)
    end
  end
  
  test 'award! with existing' do
    flexmock(Psychosis).should_receive(:insanities_for).and_return([@insanity])
    psychosis = @investigator.psychoses.create!(:insanity => @insanity, :severity => 2)
  
    assert_no_difference '@investigator.psychoses.count' do
      assert_difference 'psychosis.reload.severity', +1 do
        assert_equal true, Psychosis.award!(@investigator)
      end
    end
  end  
  
  test 'award! without insanities' do
    flexmock(Psychosis).should_receive(:insanities_for).and_return([])
    assert_equal false, Psychosis.award!(@investigator)
  end
  
  test 'degree' do
    assert_equal 'Mild', @psychosis.degree
    @psychosis.severity = 2
    assert_equal 'Aggrevated', @psychosis.degree
    @psychosis.severity = 3
    assert_equal 'Severe', @psychosis.degree   
  end
  
  test 'treatment_hours' do
    @psychosis.severity = 1
    assert_equal 9.hours, @psychosis.treatment_hours
    @psychosis.severity = 2
    assert_equal 18.hours, @psychosis.treatment_hours
    @psychosis.severity = 3
    assert_equal 27.hours, @psychosis.treatment_hours    
  end
  
  test 'treatment_threshold' do
    @psychosis.severity = 1
    assert_equal 3, @psychosis.treatment_threshold
    @psychosis.severity = 2
    assert_equal 6, @psychosis.treatment_threshold
    @psychosis.severity = 3
    assert_equal 9, @psychosis.treatment_threshold    
  end
    
  test 'begin_treatment!' do
    psychosis = @investigator.psychoses.create!(:insanity => @insanity)
    assert_difference '@investigator.psychoses.treating.count', +1 do
      assert_equal true, psychosis.begin_treatment!
      assert_not_nil psychosis.next_treatment_at
    end
  end
  
  test 'begin_treatment! with existing' do
    first = @investigator.psychoses.create!(:insanity => @insanity)
    second = @investigator.psychoses.create!(:insanity => insanities(:phobia))
    first.update_attribute(:next_treatment_at, Time.now)
    
    assert_equal false, second.begin_treatment!
    assert second.errors[:base].include?("already in treatment for a different insanity")
  end  
  
  test 'finish_treatment! with untreatable' do
    flexmock(@psychosis).should_receive(:treatable?).and_return(false)
    
    assert_equal false, @psychosis.finish_treatment!
    assert @psychosis.errors[:base].include?("must spend more time institutionalized before finishing treatment")
  end
  
  test 'finish_treatment! destroyed' do  
    @psychosis = @investigator.psychoses.create!(:insanity => @insanity)
    flexmock(@psychosis).should_receive(:treatable?).and_return(true)
    flexmock(@psychosis).should_receive(:random).and_return(10)
    assert_difference 'Psychosis.count', -1 do
      assert_equal true, @psychosis.finish_treatment!
    end
  end
  
  test 'finish_treatment! decremented' do  
    @psychosis = @investigator.psychoses.create!(:insanity => @insanity)
    @psychosis.update_attribute(:severity, 2)    
    flexmock(@psychosis).should_receive(:treatable?).and_return(true)
    flexmock(@psychosis).should_receive(:random).and_return(10)
    
    assert_no_difference 'Psychosis.count' do
      assert_difference '@psychosis.severity', -1 do
        assert_equal true, @psychosis.finish_treatment!
        @psychosis.reload
      end
    end
  end  
  
  test 'finish_treatment! failure' do
    @psychosis = @investigator.psychoses.create!(:insanity => @insanity)
    flexmock(@psychosis).should_receive(:treatable?).and_return(true)
    flexmock(@psychosis).should_receive(:random).and_return(0)
    flexmock(@psychosis).should_receive(:treatment_failed).once
    
    assert_equal false, @psychosis.finish_treatment!
    assert @psychosis.errors[:base].empty?
    assert_nil @psychosis.reload.next_treatment_at
  end
    
  test 'log_insanity' do
    psychosis = @investigator.psychoses.new(:insanity => @insanity)
    assert_difference 'InvestigatorActivity.count', +1 do
      psychosis.save
    end
    assert_equal InvestigatorActivity.last.investigator, @investigator
    assert_equal InvestigatorActivity.last.subject, @insanity
  end  
  
  test 'log_treatment' do
    psychosis = @investigator.psychoses.create!(:insanity => @insanity)
    assert_difference 'InvestigatorActivity.count', +1 do
      psychosis.destroy
    end
    assert_equal InvestigatorActivity.last.investigator, @investigator
    assert_equal InvestigatorActivity.last.subject, @insanity
  end
  
  test 'treating?' do
    assert_equal false, @psychosis.treating?
    
    @psychosis.next_treatment_at = Time.now
    assert_equal true, @psychosis.treating?    
  end
  
  test 'treatable?' do
    @psychosis.next_treatment_at = Time.now + 1.day
    assert_equal false, @psychosis.treatable?
    
    @psychosis.next_treatment_at = Time.now - 1.hour
    assert_equal true, @psychosis.treatable?    
  end  
  
  test 'random' do
    assert_operator @psychosis.send(:random), ">=", 0
    assert_operator @psychosis.send(:random), "<=", 10
  end  
  
  test 'treatment_failed' do
    flexmock(@psychosis).should_receive('investigator.award_madness!').with(@psychosis.severity).once.and_return(true)
    assert_equal true, @psychosis.send(:treatment_failed)
  end
  
  test 'remaining_time_in_percent' do
    @psychosis.next_treatment_at = Time.now - 1.minute
    assert_equal 0, @psychosis.remaining_time_in_percent

    @psychosis.next_treatment_at = Time.now + 4.5.hours
    assert_equal 50, @psychosis.remaining_time_in_percent
    
    @psychosis.next_treatment_at = Time.now + 9.hours
    assert_equal 100, @psychosis.remaining_time_in_percent
    
    @psychosis.next_treatment_at = nil
    assert_equal 100, @psychosis.remaining_time_in_percent    
  end  
end