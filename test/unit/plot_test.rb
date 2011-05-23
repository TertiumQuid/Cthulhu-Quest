require 'test_helper'

class PlotTest < ActiveSupport::TestCase
  def setup
    @investigator = investigators(:aleph_pi)
    @plot = plots(:malleus_maleficarum)
  end
  
  test 'find_starting_plots' do
    assert !Plot.find_starting_plots.blank?
  end
  
  test 'available_for?' do
    assert_operator @plot.level, "==", @investigator.level
    assert_equal true, @plot.available_for?(@investigator)
    
    @investigator.update_attribute(:level, @plot.level + 1)
    assert_equal true, @plot.available_for?(@investigator)
    
    @plot.update_attribute(:level, @investigator.level + 1)
    assert_equal false, @plot.available_for?(@investigator)
  end
end