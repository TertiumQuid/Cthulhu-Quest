class Effect < ActiveRecord::Base
  belongs_to :effecacy
  belongs_to :trigger, :polymorphic => true
  belongs_to :target, :polymorphic => true
  has_many :effections, :dependent => :destroy
end