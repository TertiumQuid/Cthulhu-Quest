require 'test_helper'

class SpellbookTest < ActiveSupport::TestCase
  def setup
    @investigator = investigators(:aleph_pi)
    @grimoire = grimoires(:the_king_in_yellow)
    @spellbook = spellbooks(:aleph_book_of_dzyan)
  end
  
  test 'set_name' do
    spellbook = @investigator.spellbooks.create(:grimoire_id => @grimoire.id)
    assert_equal @grimoire.name, spellbook.name
  end
  
  test 'unread on create' do
    spellbook = @investigator.spellbooks.create(:grimoire_id => @grimoire.id)
    assert_equal false, spellbook.read
  end
  
  test 'read?' do
    assert_equal @spellbook.read, @spellbook.read?
  end
  
  test 'read!' do
    assert_difference ['@investigator.spellbooks.read.count'], +1 do
      assert_difference ['@investigator.spellbooks.unread.count'], -1 do
        assert_difference ['@investigator.madness'], +@spellbook.grimoire.madness_cost do
          flexmock(@spellbook).should_receive(:log_reading).once
          @spellbook.read!
          assert_equal true, @spellbook.read?
          @investigator.reload
        end
      end
    end
    
    @spellbook.reload
    assert_no_difference ['@investigator.spellbooks.read.count'] do
      assert_no_difference ['@investigator.spellbooks.unread.count'] do
        assert_equal false, @spellbook.read!
      end
    end    
  end
  
  test 'read! and driven_mad?' do
    @investigator.update_attribute(:madness, @investigator.maximum_madness - 1)
    assert_equal true, @spellbook.read!
    assert_equal 0, @investigator.reload.madness
  end
  
  test 'log_reading' do
    flexmock(InvestigatorActivity).should_receive(:log).once
    @spellbook.send(:log_reading)
  end  
end