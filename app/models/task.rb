class Task < ActiveRecord::Base
  TYPES = ['funds','item','moxie','wounds','madness','spell']
  CHALLENGE_RANGE = 15
  
  belongs_to :skill
  has_many   :taskings
end