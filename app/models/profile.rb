class Profile < ActiveRecord::Base
  CHALLENGES = ['adventure','bureaucracy','conflict','research','scholarship','society','sorcery','underworld','psychology','sensitivity']
  has_many :investigators  
  has_many :profile_skills
  has_many :skills, :through => :profile_skills
  has_and_belongs_to_many :characters
end