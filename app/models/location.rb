class Location < ActiveRecord::Base
  has_and_belongs_to_many :plots
  belongs_to :location
  has_many   :characters
  has_many   :investigators
  has_many   :denizens
  has_many   :monsters, :through => :denizens
  has_many   :transits, :foreign_key => 'origin_id'
  has_many   :taskings, :as => 'owner'
  has_many   :tasks, :through => :taskings
end