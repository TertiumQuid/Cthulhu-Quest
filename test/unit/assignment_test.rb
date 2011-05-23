require 'test_helper'

class AssignmentTest < ActiveSupport::TestCase
  def setup
    @intrigue = intrigues(:troubled_dreams_1)
    @assignment = Assignment.new
    @assigned = assignments(:aleph_grandfathers_journal_beth)
    @thread = plot_threads(:aleph_troubled_dreams)
    @ally = allies(:aleph_beth)
    @contact = contacts(:aleph_thomas_malone)
    @investigation = investigations(:aleph_investigating)
  end
  
  test 'set_status' do
    @assignment.save
    assert_equal 'accepted', @assignment.status
    
    @assignment = Assignment.new(:contact_id => 1)
    @assignment.save
    assert_equal 'accepted', @assignment.status
    
    @assignment = Assignment.new(:ally_id => 1)
    @assignment.save
    assert_equal 'requested', @assignment.status    
  end  
  
  test 'set_investigator' do
    @assignment.investigation_id = @investigation.id
    @assignment.save
    assert_equal @investigation.investigator.id, @assignment.investigator_id
  end
  
  test 'successful?' do
    @assignment.result = nil
    assert_equal false, @assignment.successful?
    
    @assignment.result = 'failed'
    assert_equal false, @assignment.successful?
    
    @assignment.result = 'succeeded'
    assert_equal true, @assignment.successful?
  end
  
  test 'accepted?' do
    assert !@assignment.accepted?
    @assignment.status = 'accepted'
    assert @assignment.accepted?
  end
  
  test 'requested?' do
    @assignment.status = 'accepted'
    assert !@assignment.requested?
    @assignment.status = 'requested'
    assert @assignment.requested?
  end  
  
  test 'refused?' do
    @assignment.status = 'accepted'
    assert !@assignment.refused?
    @assignment.status = 'refused'
    assert @assignment.refused?
  end
  
  test 'is_assignable?' do
    investigator = investigators(:aleph_pi)
    assignment = Assignment.new( :intrigue_id => @intrigue.id )
    
    assert_equal false, assignment.is_assignable?(nil), "assignment should not be possible for nil user"
    
    assert_equal true, assignment.is_assignable?(investigator), "user should be assignable for challenge"
    
    assert stats(:aleph_research).update_attribute(:skill_level, 0)
    investigator.reload
    assert_equal false, assignment.is_assignable?(investigator), "user should not be assignable for challenge"
  end
  
  test 'self_assigned?' do
    @assignment.ally_id = nil
    @assignment.contact_id = 1
    assert_equal false, @assignment.self_assigned?
  
    @assignment.ally_id = 1
    @assignment.contact_id = nil
    assert_equal false, @assignment.self_assigned?    
    
    @assignment.ally_id = nil
    @assignment.contact_id = nil
    assert_equal true, @assignment.self_assigned?    
  end
  
  test 'ally_assigned?' do
    @assignment.ally_id = nil
    assert_equal false, @assignment.ally_assigned?
    
    @assignment.ally_id = 1
    assert_equal true, @assignment.ally_assigned?
  end
  
  test 'contact_assigned?' do
    @assignment.contact_id = nil
    assert_equal false, @assignment.contact_assigned?
    
    @assignment.contact_id = 1
    assert_equal true, @assignment.contact_assigned?
  end
    
  test 'assignable' do
    investigable = investigators(:aleph_pi)
    not_investigable = investigators(:beth_pi)
    stats(:beth_research).update_attribute(:skill_level, 0)
    assignment = Assignment.new( :intrigue_id => @intrigue.id )
    
    assert_equal [investigable], assignment.assignable( [investigable, not_investigable] )
    assert_equal [investigable, @contact.character], assignment.assignable( [investigable, @contact.character] )
    assert_equal [], assignment.assignable([])
    assert_equal [], assignment.assignable(nil)
  end
  
  test 'validates associations' do
    assignment = Assignment.new
    assert !assignment.valid?
    assert assignment.errors['intrigue_id'].include?("is not a number")
    assert assignment.errors['investigator_id'].include?("is not a number")
    
    assignment = Assignment.new
    
    assignment.investigator_id = 'abc'
    assignment.intrigue_id = 'abc'
    assignment.ally_id = 'abc'
    assignment.contact_id = 'abc'
    assert !assignment.valid?
    
    assert assignment.errors['intrigue_id'].include?("is not a number")
    assert assignment.errors['ally_id'].include?("is not a number")
    assert assignment.errors['contact_id'].include?("is not a number")
  end
  
  test 'validates association_authentication' do
     assignment = Assignment.new
     assignment.investigation_id = investigations(:aleph_investigating).id
     assignment.investigator = investigators(:aleph_pi)
     assignment.contact_id = 1
     assignment.ally_id = 1
     
     assert !assignment.valid?
     assert assignment.errors['ally_id'].include?("is not among your inner circle")
     assert assignment.errors['contact_id'].include?("is not known to you")
  end
  
  test 'validates status' do
    assignment = Assignment.create(:status => 'bad')
    assert assignment.errors[:status].include?("is not included in the list")
  end
  
  test 'validates status_updated' do
    assignment = assignments(:aleph_grandfathers_journal_beth)
    assignment.update_attribute(:status, 'requested')
    
    assignment.update_attribute(:status, 'accepted')
    assert !assignment.update_attributes(:status => 'requested')
    assert assignment.errors[:status].include?('can no longer be updated')
  end
  
  test 'validates challenge_matched for ally' do
    ally = allies(:aleph_beth)
    assignment = Assignment.new(:ally_id => ally.ally_id, 
                                :intrigue_id => @intrigue.id, 
                                :investigation_id => investigations(:aleph_investigating).id)
                                
    assert stats(:beth_research).update_attribute(:skill_level, 0)
    assert !assignment.save
    assert assignment.errors[:ally_id].include?('does not have expertise to meet challenge')
  end
  
  test 'validates challenge_matched for contact' do
    contact = contacts(:aleph_thomas_malone)
    assignment = Assignment.new(:contact_id => contact.id, 
                                :intrigue_id => @intrigue.id, 
                                :investigation_id => investigations(:aleph_investigating).id)
                                
    assert character_skills(:malone_research).update_attribute(:skill_level, 0)
    assert !assignment.save
    assert assignment.errors[:contact_id].include?('does not have expertise to meet challenge')
  end  
  
  test 'favors_available' do
    contact = contacts(:aleph_thomas_malone)
    contact.update_attribute(:favor_count, 0)
    assignment = Assignment.new(:contact_id => contact.id, 
                                :intrigue_id => @intrigue.id, 
                                :investigation_id => investigations(:aleph_investigating).id) 
    assert !assignment.save
    assert assignment.errors[:contact_id].include?('owes you no favors')   
  end
  
  test 'respond!' do
    @assigned.update_attribute(:status, 'refused')
    flexmock(@assigned).should_receive(:status_updated).and_return(true)
    flexmock(@assigned).should_receive(:log_investigator_response).twice
    flexmock(@assigned).should_receive(:remove_facebook_app_request).twice
    
    assert_equal true, @assigned.respond!('accepted')
    assert_equal 'accepted', @assigned.reload.status
    
    assert_equal true, @assigned.respond!(:status => 'refused')
    assert_equal 'refused', @assigned.reload.status
  end
  
  test 'investigate! success' do
    flexmock(@assigned).should_receive(:success_target).and_return(100)
    flexmock(@assigned).should_receive(:random).and_return(0)
    flexmock(@assigned).should_receive(:combat_threat!).once
    flexmock(@assigned).should_receive(:remove_facebook_app_request).once
    assert_equal true, @assigned.investigate!
    assert_equal 'succeeded', @assigned.reload.result
    assert_equal 100, @assigned.challenge_target
    assert_equal 0, @assigned.challenge_score
  end
  
  test 'investigate! failure' do
    flexmock(@assigned).should_receive(:random).and_return(100)
    flexmock(@assigned).should_receive(:remove_facebook_app_request).once
    assert_equal false, @assigned.investigate!
    assert_equal 'failed', @assigned.reload.result
  end  
  
  test 'investigate! unskilled failure' do
    flexmock(@assigned).should_receive(:success_target).and_return(0)
    flexmock(@assigned).should_receive(:random).and_return(0)
    flexmock(@assigned).should_receive(:remove_facebook_app_request).once
    assert_equal false, @assigned.investigate!
    assert_equal 'failed', @assigned.reload.result
  end
  
  test 'combat_threat!' do
    assignment = assignments(:aleph_grandfathers_journal_self_4)
    assert !assignment.intrigue.threat.blank?
    flexmock(Threat).new_instances.should_receive(:combat!).once
    assignment.combat_threat!
  end
  
  test 'fail!' do
    assignment = assignments(:aleph_grandfathers_journal_self_4)
    flexmock(assignment).should_receive(:remove_facebook_app_request).once
    
    assignment.send(:fail!)
    assignment.reload
    assert_equal 0, assignment.challenge_target
    assert_equal Intrigue::CHALLENGE_RANGE, assignment.challenge_score
    assert_equal 'failed', assignment.result
  end
  
  test 'random' do
    assert_operator @assigned.send(:random), ">=", 0
    assert_operator @assigned.send(:random), "<=", Intrigue::CHALLENGE_RANGE
  end
  
  test 'success_target' do
    investigations(:aleph_failed).destroy
    assignment = assignments(:aleph_grandfathers_journal_beth)
    assignment.update_attribute(:investigator_id, investigators(:aleph_pi).id)
    
    expected = assignment.intrigue.threshold(assignment.investigator)
    assert_equal expected, assignment.send(:success_target)
  end
  
  test 'success_target and ally' do  
    investigations(:aleph_failed).destroy
    assignment = assignments(:aleph_grandfathers_journal_beth)
    assignment.update_attribute(:status, 'accepted')
    
    expected = assignment.intrigue.threshold(assignment.investigation.investigator, assignment.ally)
    assert_equal expected, assignment.send(:success_target)    
  end
  
  test 'success_target and consecutive_failure_bonus' do
    assignment = assignments(:aleph_grandfathers_journal_beth)
    assignment.update_attribute(:investigator_id, investigators(:aleph_pi).id)
    
    expected = assignment.intrigue.threshold(assignment.investigator)
    expected = expected + 1
    assert_equal expected, assignment.send(:success_target)
  end  
  
  test 'helpers for self_assigned?' do
    assignment = Assignment.new
    assert_equal "You face this intrigue alone.", assignment.helpers
    assert_equal "You faced this intrigue alone.", assignment.helpers(:past => true)
  end
  
  test 'helpers for ally_assigned?' do
    @ally = allies(:aleph_beth)
    assignment = Assignment.new(:ally_id => @ally.ally.id)
    assert_equal "You face this intrigue alone.", assignment.helpers
    
    assignment.status = 'accepted'
    assert_equal "#{@ally.ally.name} is helping you with this intrigue.", assignment.helpers
    assert_equal "#{@ally.ally.name} helped you with this intrigue.", assignment.helpers(:past => true)
    assert_equal "<strong>#{@ally.ally.name}</strong> is helping you with this intrigue.", assignment.helpers(:html => true)
  end
  
  test 'helpers for contact_assigned?' do
    assignment = Assignment.new(:contact_id => @contact.id)
    assert_equal "#{@contact.name} is helping you with this intrigue.", assignment.helpers
    assert_equal "#{@contact.name} helped you with this intrigue.", assignment.helpers(:past => true)
    assert_equal "<strong>#{@contact.name}</strong> is helping you with this intrigue.", assignment.helpers(:html => true)
  end    
  
  test 'helpers for ally_assigned? and contact_assigned?' do
    assignment = Assignment.new(:ally_id => @ally.ally_id, :contact_id => @contact.id)
    
    assignment.status = 'accepted'
    assert_equal "#{@ally.ally.name} and #{@contact.name} are helping you with this intrigue.", assignment.helpers
    assert_equal "#{@ally.ally.name} and #{@contact.name} helped you with this intrigue.", assignment.helpers(:past => true)
  end
  
  test 'log_investigator_assignment on create' do
    @assignment.investigation = @investigation
    @assignment.intrigue = @intrigue
    flexmock(@assignment).should_receive(:log_investigator_assignment).once
    @assignment.save!
  end
  
  test 'send_facebook_app_request on create' do
    @assignment.investigation = @investigation
    @assignment.intrigue = @intrigue
    flexmock(@assignment).should_receive(:send_facebook_app_request).once
    @assignment.save!
  end  
  
  test 'log_investigator_assignment' do
    flexmock(InvestigatorActivity).should_receive(:log).once
    @assignment.investigation = @investigation
    @assignment.ally_id = nil
    @assignment.send(:log_investigator_assignment)
    @assignment.ally_id = @ally.id
    @assignment.send(:log_investigator_assignment)
  end
  
  test 'log_investigator_response ignored' do
    @assignment.investigation = @investigation
    @assignment.ally_id = nil
    @assignment.send(:log_investigator_response)
  end
  
  test 'log_investigator_response refused' do
    flexmock(InvestigatorActivity).should_receive(:log).once
    @assignment.status = 'refused'
    @assignment.investigation = @investigation
    @assignment.ally_id = @ally.id
    @assignment.send(:log_investigator_response)
  end
  
  test 'log_investigator_response accepted' do
    flexmock(InvestigatorActivity).should_receive(:log).twice
    @assignment.status = 'accepted'
    @assignment.investigation = @investigation
    @assignment.ally_id = @ally.id
    @assignment.send(:log_investigator_response)
  end
  
  test 'send_facebook_app_request' do
    flexmock(Rails).should_receive('env.production?').and_return(true)
    flexmock(@assigned).should_receive('ally.user.name').and_return('test')
    flexmock(@assigned).should_receive('save').once.and_return(true)
    flexmock(@assigned).should_receive('ally.user.send_app_request').with(String,@assigned.id).and_return('1010101').once
    
    assert_equal '1010101', @assigned.send(:send_facebook_app_request)
    assert_equal '1010101', @assigned.facebook_request_id
  end  
  
  test 'send_facebook_app_request without ally' do
    flexmock(Rails).should_receive('env.production?').and_return(true)
    flexmock(@assigned).should_receive('save').times(0)
    flexmock(@assignment).should_receive('ally.user.send_app_request').times(0)
    
    assert_nil @assignment.send(:send_facebook_app_request)
  end
  
  test 'send_facebook_app_request with error' do
    flexmock(Rails).should_receive('env.production?').and_return(true)
    flexmock(@assigned).should_receive('ally.user.name').and_return('test')
    flexmock(@assigned).should_receive('save').once.and_return(true)
    flexmock(@assigned).should_receive('ally.user.send_app_request').and_raise(StandardError).once
    
    assert_nil @assigned.send(:send_facebook_app_request)
    assert_nil @assigned.facebook_request_id
  end  
  
  test 'remove_facebook_app_request' do
    flexmock(Rails).should_receive('env.production?').and_return(true)
    @assigned.update_attribute(:facebook_request_id, '1010101')
    flexmock(@assigned).should_receive('ally.user.name').and_return('test')
    flexmock(@assigned).should_receive('ally.user.remove_app_request').with('1010101').once
    
    @assigned.send(:remove_facebook_app_request)
    assert_nil @assigned.facebook_request_id
  end  
  
  test 'remove_facebook_app_request without ally' do
    flexmock(Rails).should_receive('env.production?').and_return(true)
    flexmock(@assignment).should_receive('ally.user.remove_app_request').times(0)
    
    assert_nil @assignment.send(:remove_facebook_app_request)
  end  
  
  test 'remove_facebook_app_request without facebook_request_id' do
    flexmock(Rails).should_receive('env.production?').and_return(true)
    @assigned.update_attribute(:facebook_request_id, nil)
    flexmock(@assignment).should_receive('ally.user.remove_app_request').times(0)
    
    @assigned.send(:remove_facebook_app_request)
    assert_nil @assigned.facebook_request_id
  end  
  
  test 'remove_facebook_app_request with error' do
    flexmock(Rails).should_receive('env.production?').and_return(true)
    @assigned.update_attribute(:facebook_request_id, '1010101')
    flexmock(@assigned).should_receive('ally.user.name').and_return('test')
    flexmock(@assigned).should_receive('ally.user.remove_app_request').and_raise(StandardError).once
    
    @assigned.send(:remove_facebook_app_request)
    assert_nil @assigned.facebook_request_id
  end  
end