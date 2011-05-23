require 'test_helper'

class PrerequisiteTest < ActiveSupport::TestCase
  def setup
    @investigator = investigators(:gimel_pi)
    @investigator.casebook << PlotThread.new(:investigator_id => @investigator.id, :plot_id => plots(:fire_in_the_sky).id)
  end
    
  test 'requirement empty' do  
    prereq = Prerequisite.new
    assert_nil prereq.requirement
  end
    
  test 'requirement for plot' do
    plot = plots(:troubled_dreams)
    prereq = Prerequisite.new(:requirement_type => 'plot', :requirement_id => plot.id)
    assert_equal plot, prereq.requirement
  end
  
  test 'requirement for item' do
    item = items(:crowbar)
    prereq = Prerequisite.new(:requirement_type => 'item', :requirement_id => item.id)
    assert_equal item, prereq.requirement
  end 
  
  test 'requirement for funds' do
    prereq = plots(:hellfire_club).prerequisites.create(:requirement_id => 10, :requirement_type => 'funds', :requirement_name => 'Funding')
    assert_equal 10, prereq.requirement
  end   
  
  test 'has_funds?' do
    pre = plots(:hellfire_club).prerequisites.create(:requirement_id => 10, :requirement_type => 'funds', :requirement_name => 'Funding')
    
    @investigator.update_attribute(:funds, 9)
    assert_equal false, pre.send(:has_funds?, @investigator)
    @investigator.update_attribute(:funds, 10)
    assert_equal true, pre.send(:has_funds?, @investigator)
  end
  
  test 'has_item?' do
    pre = prerequisites(:troubled_dreams_notebook)
    assert_equal false, pre.send(:has_item?, @investigator)
    assert_equal true, pre.send(:has_item?, @investigator, [pre.requirement_id])

    item_ids = [pre.requirement_id]
    assert_equal true, pre.send(:has_item?, @investigator, item_ids)
    
    @investigator.possessions.create(:item_id => pre.requirement_id)
    assert_equal true, pre.send(:has_item?, @investigator)
  end
  
  test 'solved_plot?' do
    @investigator.casebook.destroy_all
    @investigator.casebook << PlotThread.create!(:investigator_id => @investigator.id, :plot_id => plots(:troubled_dreams).id)
    
    pre = prerequisites(:fire_in_the_sky_troubled_dreams)
    assert_equal false, pre.send(:solved_plot?, @investigator)
    assert_equal true, pre.send(:solved_plot?, @investigator, [pre.requirement_id])
    
    @investigator.casebook.first.update_attribute(:status, 'solved')
    @investigator.reload
    assert_equal true, pre.send(:solved_plot?, @investigator)
  end  
  
  test 'satisfied? for has_funds?' do
    pre = plots(:hellfire_club).prerequisites.create(:requirement_id => 10, :requirement_type => 'funds', :requirement_name => 'Funding')
    
    @investigator.update_attribute(:funds, 9)
    assert_equal false, pre.satisfied?( @investigator)
    @investigator.update_attribute(:funds, 10)
    assert_equal true, pre.satisfied?( @investigator)
  end  
  
  test 'satisfied? for has_item?' do
    pre = prerequisites(:troubled_dreams_notebook)
    assert_equal false, pre.satisfied?( @investigator)
    
    @investigator.possessions.create(:item_id => pre.requirement_id)
    assert_equal true, pre.satisfied?( @investigator)
  end
  
  test 'satisfied? for has_item? with item_ids' do
    pre = prerequisites(:troubled_dreams_notebook)
    assert_equal false, pre.satisfied?( @investigator)
    item_ids = [pre.requirement_id]
    
    flexmock(pre).should_receive(:has_item?).with( @investigator, item_ids ).and_return(true).once
    assert_equal true, pre.satisfied?( @investigator, item_ids)
  end
  
  test 'satisfied? for solved_plot?' do
    @investigator.casebook.destroy_all
    @investigator.casebook << PlotThread.create!(:investigator_id => @investigator.id, :plot_id => plots(:troubled_dreams).id)
    
    pre = prerequisites(:fire_in_the_sky_troubled_dreams)
    assert_equal false, pre.satisfied?( @investigator )
    @investigator.casebook.first.update_attribute(:status, 'solved')
    @investigator.reload
    assert_equal true, pre.satisfied?( @investigator )
  end  
  
  test 'validate_investigation for funds' do
    investigation = Investigation.first
    pre = investigation.plot.prerequisites.create(:requirement_id => 10, :requirement_type => 'funds', :requirement_name => 'Funding')
    investigation.investigator.update_attribute(:funds, 9)
    
    assert_equal false, Prerequisite.validate_investigation( investigation )
    assert investigation.errors[:base].include?("you don't posses enough funds: £10")
    
    investigation.investigator.update_attribute(:funds, 10)
    investigation = @investigator.casebook.first
    Prerequisite.validate_investigation( investigation )
    assert !investigation.errors[:base].include?("you don't posses enough funds: £10")
  end
  
  test 'validate_investigation for item' do
    plot_threads(:gimel_troubled_dreams).destroy
    thread = @investigator.casebook.first
    investigation = thread.investigations.build
    
    assert_equal false, Prerequisite.validate_investigation( investigation )
    assert investigation.errors[:base].include?("hasn't solved required plot: Troubled Dreams")
    assert investigation.errors[:base].include?("you don't posses the required item: Notebook")
    
    investigation = thread.investigations.build
    @investigator.possessions.create(:item_id => prerequisites(:troubled_dreams_notebook).requirement_id)
    solved = @investigator.casebook.new(:plot_id => prerequisites(:fire_in_the_sky_troubled_dreams).requirement_id, :status => 'solved')
    solved.save!(:validates => false)

    assert_equal true, Prerequisite.validate_investigation( investigation )
    assert !investigation.errors[:base].include?("hasn't solved required plot: Troubled Dreams")
    assert !investigation.errors[:base].include?("you don't posses the required item: Notebook")
  end
end