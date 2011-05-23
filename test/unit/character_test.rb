require 'test_helper'

class CharacterTest < ActiveSupport::TestCase
  def setup
    @character = characters(:henry_armitage)
  end
  
  test 'skill methods' do
    [:adventure,:bureaucracy,:conflict,:research,:scholarship,
    :society,:sorcery,:underworld,:psychology,:sensitivity].each do |skill|
      assert @character.respond_to?(skill)
    end
  end  
end