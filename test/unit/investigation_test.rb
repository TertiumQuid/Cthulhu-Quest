require 'test_helper'

class InvestigationTest < ActiveSupport::TestCase
  def setup
    @plot_thread = plot_threads(:aleph_grandfathers_journal)
    @investigator = investigators(:aleph_pi)
    @investigation = investigations(:aleph_investigating)
  end
  
  def set_investigation_for_solving(investigation=nil)
    investigation ||= @investigation
    @solution = investigation.plot.solutions.first
    investigation.update_attribute(:status, 'completed')
    investigation.plot_thread.update_attribute(:status, 'available')
    flexmock(investigation).should_receive(:log_success).once    
  end
  
  test 'validates_availability' do
    invalid = plot_threads(:aleph_troubled_dreams).investigations.create
    invalid.plot_thread.update_attribute(:status, 'investigating')
    assert !invalid.valid?, "plot thread should be invalid"
    assert invalid.errors[:base].include?("unavailable for investigation")
  end  
  
  test 'validates_concurrency' do
    invalid = plot_threads(:aleph_troubled_dreams).investigations.create
    assert !invalid.valid?, "plot thread should be invalid"
    assert invalid.errors[:base].include?("already preoccupied with other investigations")
  end
  
  test 'validates_assignments blank' do
    invalid = plot_threads(:aleph_troubled_dreams).investigations.create
    assert invalid.errors[:base].include?("must assign an investigator to every intrigue")
  end
  
  test 'validates_assignments mismatch' do
    invalid = plot_threads(:aleph_troubled_dreams).investigations.new
    invalid.plot.intrigues.each do |i|
      invalid.assignments.build(:intrigue_id => intrigues(:grandfathers_journal_1).id )
    end
    assert !invalid.save
    assert invalid.errors[:base].include?("intrigue does not match plot")
  end
  
  test 'validates_ally_exclusivity' do
    ally = allies(:aleph_beth)
    invalid = plot_threads(:aleph_troubled_dreams).investigations.new
    invalid.plot.intrigues.each do |i|
      invalid.assignments.build(:intrigue_id => i.id, :ally_id => ally.id )
    end
    assert !invalid.save
    assert invalid.errors[:base].include?("ally cannot be assigned to multiple intrigues")
  end
  
  test 'validates_contact_exclusivity' do
    contact = contacts(:aleph_henry_armitage)
    invalid = plot_threads(:aleph_troubled_dreams).investigations.new
    
    invalid.build_assignments
    
    invalid.assignments.each do |assignment|
      assignment.contact_id = contact.id
    end
    assert !invalid.save
    assert invalid.errors[:base].include?("contact cannot be assigned to multiple intrigues")
  end  
  
  test 'validates_prerequisites' do
    investigator = investigators(:gimel_pi)
    plot = plots(:fire_in_the_sky)
    thread = investigator.casebook.create(:investigator_id => @investigator.id, :plot_id => plot.id)
    invalid = thread.investigations.build
    assert !invalid.save
    assert invalid.errors[:base].include?("you don't posses the required item: Notebook")
    assert invalid.errors[:base].include?("hasn't solved required plot: Troubled Dreams")
  end
  
  test 'set_moxie' do
    investigation = Investigation.create
    assert_equal 0, investigation.moxie_speed
    assert_equal 0, investigation.moxie_challenge
  
    investigation = @investigator.investigations.create(:moxie_speed => 1, :moxie_challenge => 1)
    assert_equal 1, investigation.moxie_speed
    assert_equal 0, investigation.moxie_challenge
  end
  
  test 'set_status' do
    investigation = Investigation.create
    assert_equal 'active', investigation.status
    
    investigation = Investigation.create(:status => 'completed')
    assert_equal 'active', investigation.status
  end
  
  test 'set_plot_title' do
    investigation = Investigation.create(:plot_thread_id => @plot_thread.id)
    assert_equal @plot_thread.plot_title, investigation.plot_title
  end  
  
  test 'plot' do
    assert_equal @plot_thread.plot, @investigation.plot
    @investigation.plot_thread = nil
    assert_nil @investigation.plot
  end
  
  test 'investigator' do
    assert_equal @plot_thread.investigator, @investigation.investigator
    @investigation.plot_thread = nil
    assert_nil @investigation.investigator
  end  
  
  test 'active?' do
    assert_equal true, @investigation.active?
    @investigation.update_attribute(:status, 'completed')
    assert_equal false, @investigation.active?
  end
  
  test 'solved?' do
    assert_equal false, @investigation.solved?
    @investigation.update_attribute(:status, 'solved')
    assert_equal true, @investigation.solved?
  end  
  
  test 'unsolved?' do
    assert_equal false, @investigation.unsolved?
    @investigation.update_attribute(:status, 'unsolved')
    assert_equal true, @investigation.unsolved?
  end
    
  test 'investigated?' do
    assert_equal false, @investigation.investigated?
    @investigation.update_attribute(:status, 'investigated')
    assert_equal true, @investigation.investigated?
  end  
  
  test 'completed?' do
    assert_equal false, @investigation.completed?
    @investigation.update_attribute(:status, 'completed')
    assert_equal true, @investigation.completed?
  end  
  
  test 'advance_state! for elapsed?' do
    @investigation.update_attribute(:status, 'active')
    flexmock(@investigation).should_receive(:elapsed?).and_return(true)
    flexmock(@investigation).should_receive(:elapse!).and_return('test').once
    assert_equal 'test', @investigation.advance_state!
  end
  
  test 'advance_state! for investigated?' do
    @investigation.update_attribute(:status, 'investigated')
    flexmock(@investigation).should_receive(:complete!).and_return('test').once
    assert_equal 'test', @investigation.advance_state!
  end
  
  test 'advance_state! for completed?' do
    solution = @investigation.plot.solutions.first
    @investigation.update_attribute(:status, 'completed')
    flexmock(@investigation).should_receive(:solve!).with(solution).and_return('test').once
    assert_equal 'test', @investigation.advance_state!(solution)
  end  
  
  test 'complete! not investigated' do
    @investigation.update_attribute(:status, 'active')
    assert_equal false, @investigation.complete!
    assert_nil @investigation.finished_at
    assert @investigation.errors[:base].include?("cannot be completed yet")
  end
  
  test 'complete! success' do
    @investigation.update_attribute(:status, 'investigated')
    flexmock(@investigation).should_receive(:do_intrigue_challenges).and_return(true)
    flexmock(@investigation).should_receive(:set_unanswered_assignments).once
    assert_equal true, @investigation.complete!
    assert_equal 'completed', @investigation.reload.status
    assert_not_nil @investigation.finished_at
  end  
  
  test 'complete! failure' do
    @investigation.update_attribute(:status, 'investigated')
    @investigation.plot_thread.update_attribute(:status, 'investigating')
    flexmock(@investigation).should_receive(:do_intrigue_challenges).and_return(false)
    flexmock(@investigation).should_receive(:set_unanswered_assignments).once
    flexmock(@investigation).should_receive(:log_failure).once
    
    assert_equal false, @investigation.complete!
    assert_equal 'unsolved', @investigation.reload.status
    assert_equal 'available', @investigation.plot_thread.reload.status
  end  
  
  test 'solve! not completed' do
    @investigation.update_attribute(:status, 'solved')
    assert_no_difference '@investigator.madness' do
      assert_equal false, @investigation.solve!(nil)
    end
    assert @investigation.errors[:base].include?("cannot currently be solved")
  end
  
  test 'solve! requires solution' do
    @investigation.update_attribute(:status, 'completed')
    assert_no_difference '@investigator.madness' do
      assert_equal false, @investigation.solve!(nil)
    end
    assert @investigation.errors[:base].include?("solution cannot be blank")
  end  
  
  test 'solve! with solution model' do
    set_investigation_for_solving
  
    assert_difference '@investigator.madness', +@investigation.plot.madness do    
      assert_difference '@investigator.investigations.completed.count', -1 do
        assert_difference ['@investigator.casebook.solved.count','@investigator.investigations.solved.count'], +1 do
          assert_equal true, @investigation.solve!(@solution)
          @investigation.reload
          @investigator.reload
          assert_equal 'solved', @investigation.status
          assert_equal 'solved', @investigation.plot_thread.status
          assert_equal @solution.id, @investigation.plot_thread.solution_id
        end
      end  
    end
  end  
  
  test 'solve! with solution id' do
    set_investigation_for_solving
    
    assert_difference '@investigator.madness', +@investigation.plot.madness do        
      assert_difference '@investigator.investigations.completed.count', -1 do
        assert_difference ['@investigator.casebook.solved.count','@investigator.investigations.solved.count'], +1 do
          assert_equal true, @investigation.solve!(@solution.id)
          @investigation.reload
          @investigator.reload
          assert_equal 'solved', @investigation.status
          assert_equal 'solved', @investigation.plot_thread.status
          assert_equal @solution.id, @investigation.plot_thread.solution_id
        end
      end
    end
  end  
  
  test 'hasten!' do
    @investigation.investigator.update_attribute(:moxie, @investigation.duration)
    @investigation.created_at = Time.now
    assert_operator @investigation.remaining_hours, ">", 0
    
    assert_difference '@investigator.moxie', -@investigation.duration do
      assert_difference '@investigator.investigations.active.count', -1 do
        assert_difference '@investigator.investigations.investigated.count', +1 do
          assert_equal true, @investigation.hasten!
          @investigator.reload
        end
      end
    end
  end
  
  test 'hasten! failed' do
    @investigation.investigator.update_attribute(:moxie, 0)
    @investigation.created_at = Time.now
    assert_operator @investigation.remaining_hours, ">", 0
    assert_equal false, @investigation.hasten!
    assert @investigation.errors[:moxie_speed].include?( "not enough moxie to finish your investigation" )
  end
  
  test 'hasten! non active' do
    investigation = investigations(:aleph_failed)
    assert_equal true, investigation.elapsed? && investigation.hasten!
  end
  
  test 'speedy_investigation' do
    thread = plot_threads(:gimel_troubled_dreams)
    investigator = investigators(:gimel_pi)
    investigator.update_attribute(:moxie, thread.plot.duration)
    investigation = investigator.investigations.new(:plot_thread_id => thread.id)
    investigation.build_assignments
    investigation.assignments.each do |a|
      a.intrigue.update_attribute(:difficulty, 0)
      a.investigator_id = investigator.id
    end
    
    investigation.plot_thread.update_attribute(:status, 'available')
    investigation.moxie_speed = thread.plot.duration
    
    assert_difference ['investigation.investigator.reload.moxie'], -investigation.moxie_speed do
      assert_difference ['Investigation.investigated.count'], +1 do
        assert investigation.save
        assert investigation.save
      end
    end
    assert_equal 'investigated', investigation.status
  end
    
  test 'set_duration' do
    investigation = Investigation.create(:plot_thread_id => @plot_thread.id)
    assert_equal @plot_thread.plot.duration, investigation.duration
    assert_operator investigation.duration, ">", 0
  end  
  
  test 'update_plot_thread' do
    investigation = @investigation.dup
    investigation.build_assignments
    investigation.assignments.each do |a|
      a.investigator_id = investigation.investigator.id
    end
    
    @investigation.destroy
    investigation.plot_thread.update_attribute(:status, 'available')
    
    assert investigation.save!
    assert_equal 'investigating', investigation.plot_thread.reload.status
  end  
  
  test 'elapse' do
    @investigation.update_attribute( :created_at, Time.now - 1.day )
    @investigation.update_attribute( :status, 'active' )
    
    assert_nil Investigation.active.elapse(0)
    
    assert_difference 'Investigation.investigated.count', +1 do
      assert_difference 'Investigation.active.count', -1 do
        assert_equal @investigation, Investigation.active.elapse( @investigation.id )
      end
    end
  end
  
  test 'elapse_all' do
    @investigation.update_attribute( :created_at, Time.now - 1.day )
    @investigation.update_attribute( :status, 'active' )
  
    assert_difference 'Investigation.investigated.count', +1 do
      assert_difference 'Investigation.active.count', -1 do
        investigations = Investigation.active.elapse_all
        assert investigations.blank?
      end
    end
  end  
  
  test 'elapse_all blank' do
    @investigation.update_attribute( :created_at, Time.now )
    @investigation.update_attribute( :status, 'active' )
    
    assert_no_difference ['Investigation.investigated.count','Investigation.active.count'] do
      investigations = Investigation.active.elapse_all
      assert !investigations.blank?
    end  
  end
  
  test 'build_assignments' do
    @investigation.assignments.destroy_all
    
    assert_difference '@investigation.assignments.size', @investigation.plot.intrigues.size do
      @investigation.build_assignments
      assert !@investigation.assignments.blank?
    end
    assert_equal @investigation.plot.intrigues, @investigation.assignments.map(&:intrigue)
  end
  
  test 'build_assignments with previous successful assignments' do 
    investigation = investigations(:beth_zohar_investigating)
    assignments = investigation.assignments.successful
    successful_assignment_count = investigation.plot_thread.assignments.successful.group('intrigue_id').count.size
    assert_operator successful_assignment_count, ">", 0
    assert_operator successful_assignment_count, "<", investigation.assignments.count
    
    investigation = Investigation.new(:plot_thread => investigation.plot_thread)
    assert_difference 'investigation.assignments.size', investigation.plot.intrigues.size do
      investigation.build_assignments
    end
    
    investigation.assignments.each do |assignment|
      assert assignment.new_record?
      successful = assignments.select{|a| a.intrigue_id == assignment.intrigue_id}.first
      if successful
        assert_equal 'succeeded', assignment.result
        assert_equal assignment.challenge_target, successful.challenge_target
        assert_equal assignment.challenge_score, successful.challenge_score        
      else
        assert_nil assignment.result
        assert_nil assignment.challenge_target
        assert_nil assignment.challenge_score
      end
    end
  end
  
  test 'build_assignments ignored with assignments' do
    assert_no_difference '@investigation.assignments.size' do
      @investigation.build_assignments
    end
    @investigation.assignments.each do |a|
      assert_equal @investigation.id, a.investigation_id
    end
  end
  
  test 'build_assignments without plot' do
    invalid = Investigation.create
    assert_no_difference 'invalid.assignments.size' do
      invalid.build_assignments
    end    
  end
  
  test 'build_successful_assignments' do
    previous_investigation = investigations(:beth_zohar_failed)
    
    params = {:assignments_attributes => {}}
    previous_investigation.plot_thread.plot.intrigues.each_with_index do |intrigue,idx|
      params[:assignments_attributes][idx.to_s] = {:intrigue_id => intrigue.id, :investigator_id => previous_investigation.plot_thread.investigator_id} 
    end    
    investigation = previous_investigation.plot_thread.investigations.new( params )
    
    assert !investigation.assignments.blank?
    assert investigation.assignments.select{|a| a.successful? }.blank?
    
    investigation.send(:build_successful_assignments)
    successful_count = previous_investigation.assignments.successful.count
    successful_assignments = investigation.assignments.select{|a| a.successful? }
    
    assert_operator successful_count, ">", 0
    assert_operator successful_count, "<", investigation.assignments.size
    assert_equal successful_count, successful_assignments.size
    
    successful_assignments.each do |a|
      previous_assignment = previous_investigation.assignments.successful.where(:intrigue_id => a.intrigue_id).first
      assert_equal 'succeeded', a.result
      assert_equal previous_assignment.challenge_target, a.challenge_target
      assert_equal previous_assignment.challenge_score, a.challenge_score
    end
  end  
  
  test 'build_successful_assignments without previous successful assignments' do
    plot_thread = plot_threads(:gimel_troubled_dreams)
    
    params = {:assignments_attributes => {}}
    plot_thread.plot.intrigues.each_with_index do |intrigue,idx|
      params[:assignments_attributes][idx.to_s] = {:intrigue_id => intrigue.id, :investigator_id => plot_thread.investigator_id} 
    end    
    investigation = plot_thread.investigations.new( params )
    investigation.send(:build_successful_assignments)
    
    assert !investigation.assignments.blank?
    assert investigation.assignments.select{|a| a.successful? }.blank?
  end
  
  test 'do_intrigue_challenges success' do
    investigation = investigations(:aleph_investigating)
    investigation.assignments.each { |a| flexmock(a).should_receive(:successful?).and_return(true) }
    assert_equal true, investigation.send(:do_intrigue_challenges)
  end
  
  test 'do_intrigue_challenges failure' do
    investigation = investigations(:aleph_investigating)
    investigation.assignments.each { |a| flexmock(a).should_receive(:successful?).and_return(false) }
    assert_equal false, investigation.send(:do_intrigue_challenges)
  end  
  
  test 'do_intrigue_challenges with previous successful assignments' do
    investigation = investigations(:beth_zohar_investigating)
    successful_assignment_count = investigation.plot_thread.assignments.successful.group('intrigue_id').count.size
    assert_operator successful_assignment_count, ">", 0
    assert_operator successful_assignment_count, "<", investigation.assignments.count
    
    investigation.assignments.each_with_index do |a,idx| 
      if idx <= successful_assignment_count
        flexmock(a).should_receive(:successful?).once.and_return(true)
      else
        flexmock(a).should_receive(:successful?).twice.and_return(false)
      end
    end
    investigation.send(:do_intrigue_challenges)
  end
  
  test 'do_intrigue_challenges and skip remaining after failure' do
    investigations(:beth_zohar_failed).destroy
    investigation = investigations(:beth_zohar_investigating)
    investigation.assignments.each_with_index do |a,idx| 
      if idx == 0
        flexmock(a).should_receive(:investigate!).once
        flexmock(a).should_receive(:fail!).times(0)
      else
        flexmock(a).should_receive(:fail!).once
        flexmock(a).should_receive(:investigate!).times(0)
      end  
      flexmock(a).should_receive(:successful?).and_return(false)
    end    
    
    investigation.send(:do_intrigue_challenges)
  end
  
  test 'use_items' do
    prerequisite = prerequisites(:troubled_dreams_notebook)
    prerequisite.update_attribute(:plot_id, @plot_thread.plot_id)
    @investigator.possessions.create(:item_id => prerequisite.requirement_id)
    Investigation.destroy_all
    
    @plot_thread.update_attribute(:status, 'available')
    investigation = @plot_thread.investigations.build(:status => 'active')
    investigation.build_assignments
    
    investigation.assignments.each do |a|
      a.investigator_id = investigation.investigator.id
    end
    assert_difference '@investigator.possessions.count', -1 do
      investigation.save
    end
  end
  
  test 'reward_investigators for investigator' do
    funds = rewards(:grandfathers_journal_funds).reward_id
    investigation = investigations(:aleph_investigating)
    ally = investigation.assignments.first.investigator
    assignment = assignments(:aleph_grandfathers_journal_beth)
    reward = rewards(:grandfathers_journal_funds)
    
    investigation.update_attribute(:status, 'completed')
    assert_difference 'investigation.investigator.funds', +reward.reward_id do
      assert_no_difference 'ally.reload.experience' do
        assert investigation.solve!( investigation.plot.solutions.first )
      end
    end
  end  
  
  test 'reward_investigators for allies' do  
    investigation = investigations(:aleph_investigating)
    assignment = assignments(:aleph_grandfathers_journal_beth)
    
    assignment.update_attribute(:status, 'accepted')
    investigation.update_attribute(:status, 'completed')
    flexmock(InvestigatorActivity).should_receive(:log)
    
    assert_difference 'assignment.ally.reload.experience', +1 do
      assert investigation.solve!( investigation.plot.solutions.first )
    end
  end
  
  test 'investigation_ends_at_in_words' do
    @investigation.update_attribute(:duration,1)
    
    @investigation.update_attribute(:created_at, Time.now - 2.hours)
    ['completed','solved','unsolved'].each do |s|
      @investigation.update_attribute(:status,s)
      assert_equal "about 1 hour ago", @investigation.investigation_ends_at_in_words
    end
    
    @investigation.update_attribute(:created_at, Time.now - 30.minutes)
    ['active','investigated'].each do |s|
      @investigation.update_attribute(:status,s)
      assert_equal "30 minutes", @investigation.investigation_ends_at_in_words
    end
  end
  
  test 'remaining_hours' do
    @investigation.update_attribute(:duration, 3)
    @investigation.update_attribute(:created_at, Time.now - 1.day)
    @investigation.update_attribute(:status, 'investigated')
    assert_equal 0, @investigation.remaining_hours
    @investigation.update_attribute(:status, 'active')
    assert_equal 0, @investigation.remaining_hours
    @investigation.update_attribute(:created_at, Time.now - 30.minutes)
    assert_equal 3, @investigation.remaining_hours
    @investigation.update_attribute(:created_at, Time.now - 150.minutes)
    assert_equal 1, @investigation.remaining_hours
  end
  
  test 'set_assignment_owner for new' do
    params = {:assignments_attributes => {}}
    @plot_thread.plot.intrigues.each_with_index do |intrigue,idx|
      params[:assignments_attributes][idx.to_s] = {} 
    end    
    investigation = Investigation.new(params)
    investigation.set_assignment_owner
    assert !investigation.assignments.blank?
    investigation.assignments.each do |a|
      assert_equal investigation, a.investigation
    end
  end  
  
  test 'set_assignment_owner for existing' do
    @investigation.set_assignment_owner
    @investigation.assignments.each do |a|
      assert_equal @investigation, a.investigation
    end
  end
  
  test 'validates_moxie on create' do
    investigation = Investigation.create(:moxie_speed => 1, :moxie_challenge => 1)
    assert investigation.errors[:moxie_speed].blank?
    assert investigation.errors[:moxie_challenge].blank?
    assert_equal 0, investigation.moxie_challenge
    assert_equal 1, investigation.moxie_speed
    
    investigation = @investigator.investigations.create(:plot_thread_id => @plot_thread.id, :moxie_speed => 1, :moxie_challenge => 1)
    assert investigation.errors[:moxie_speed].blank?
    assert investigation.errors[:moxie_challenge].blank?    
    
    investigation = @investigator.investigations.create(:plot_thread_id => @plot_thread.id, :moxie_speed => 10, :moxie_challenge => 10)
    assert !investigation.errors[:moxie_speed].blank?    
    assert investigation.errors[:moxie_challenge].blank?
    
    @investigation.moxie_speed = 10
    @investigation.moxie_challenge = 10
    assert !@investigation.save
    assert !@investigation.errors[:moxie_speed].blank?    
    assert !@investigation.errors[:moxie_challenge].blank?    
  end
  
  test 'consecutive_failure_bonus' do
    failed = investigations(:aleph_failed)
    investigating = investigations(:aleph_investigating)
    assert_equal 0, Investigation.new.consecutive_failure_bonus
    assert_equal 1, failed.send(:consecutive_failure_bonus)
    assert_equal 1, investigating.consecutive_failure_bonus
    failed.update_attribute(:plot_thread_id, plot_threads(:aleph_troubled_dreams).id)
    assert_equal 0, investigating.consecutive_failure_bonus
  end  
  
  test 'use_favors' do
    contact = contacts(:aleph_thomas_malone)
    contact.update_attribute(:favor_count, 10)
    
    assignment = @investigation.assignments.first
    assignment.update_attribute(:contact_id, contact.id)
    
    assert_difference 'contact.reload.favor_count', -1 do
      assert @investigation.send(:use_favors)
    end
  end  
  
  test 'use_favors on create' do
    thread = plot_threads(:gimel_troubled_dreams)
    contact = contacts(:gimel_henry_armitage)
    investigation = thread.investigations.build
    investigation.build_assignments
    investigation.assignments.first.contact_id = contact.id
    
    assert_difference 'contact.reload.favor_count', -1 do
      assert investigation.save
    end
    
    flexmock(investigation).should_receive(:use_favors).times(0)
    investigation.save
  end
  
  test 'set_unanswered_assignments' do
    assignment = assignments(:aleph_grandfathers_journal_beth)
    unchanged = assignments(:aleph_grandfathers_journal_self_1)
    assert_equal 'requested', assignment.status
    
    investigation = assignment.investigation
    investigation.send(:set_unanswered_assignments)
    
    assert_equal 'unanswered', assignment.reload.status
    assert_equal 'accepted', unchanged.reload.status
  end
  
  test 'log_investigation on create' do
    thread = plot_threads(:gimel_troubled_dreams)
    investigation = thread.investigations.new
    investigation.build_assignments
    flexmock(investigation).should_receive(:log_investigation).once
    investigation.save
  end
  
  test 'log_investigation' do
    flexmock(InvestigatorActivity).should_receive(:log).once
    @investigation.send(:log_investigation)
  end
  
  test 'log_failure' do
    flexmock(InvestigatorActivity).should_receive(:log).once
    @investigation.send(:log_failure)
  end
  
  test 'log_success' do
    flexmock(InvestigatorActivity).should_receive(:log).once
    @investigation.send(:log_success)
  end
  
  test 'open scope' do
    @investigation.update_attribute(:status, 'solved')
    assert !Investigation.open.where(:id => @investigation.id).exists?
    @investigation.update_attribute(:status, 'unsolved')
    assert !Investigation.open.where(:id => @investigation.id).exists?
    ['active','investigated','completed'].each do |s|
      @investigation.update_attribute(:status, s)
      assert Investigation.open.where(:id => @investigation.id).exists?
    end
  end
  
  test 'remaining_time_in_percent' do
    @investigation.created_at = Time.now
    assert_equal 100, @investigation.remaining_time_in_percent
    
    @investigation.created_at = Time.now - (@investigation.duration.to_f / 2.0).hours
    assert_equal 50, @investigation.remaining_time_in_percent
    
    @investigation.created_at = Time.now - @investigation.duration.hours
    assert_equal 0, @investigation.remaining_time_in_percent
  end  
  
  test 'award_madness' do
    madness = @investigation.plot.madness
    assert_operator madness, ">", 0
    assert_difference '@investigation.investigator.madness', +madness do
      @investigation.send(:award_madness)
    end
  end
end