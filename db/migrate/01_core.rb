class Core < ActiveRecord::Migration
  def self.up
    create_table :users do |t|
      t.integer :investigator_id
      t.string :name, :limit => 256, :null => false
      t.string :full_name, :limit => 512, :null => false
      t.string :email, :limit => 256, :null => false
      t.string :facebook_id, :limit => 32
      t.string :facebook_token, :limit => 512
      t.string :nonce, :limit => 128
      t.string :password, :limit => 32
      t.text :facebook_friend_ids
      t.timestamp :last_login_at
      t.timestamp :last_facebook_update_at
      t.timestamps
    end
    add_index :users, :investigator_id
    add_index :users, :facebook_id
    
    create_table :sessions do |t|
      t.belongs_to :user
      t.string :session_id
      t.text :data
      t.timestamps
    end
    add_index :sessions, :user_id
    add_index :sessions, :session_id    
    
    create_table :skills do |t|
      t.string :name, :limit => 32
    end

    create_table :profiles do |t|
      t.string :name, :limit => 32
      t.integer :income, :null => false, :default => 0
    end
    
    create_table :profile_skills do |t|
      t.belongs_to :profile, :null => false
      t.belongs_to :skill, :null => false
      t.string :skill_name, :null => false, :limit => 32
      t.integer :skill_level, :null => false, :default => 0
    end
    add_index :profile_skills, [:profile_id, :skill_id], :unique => true
    
    create_table :investigators do |t|
      t.belongs_to :profile, :null => false
      t.belongs_to :user
      t.belongs_to :armed
      t.belongs_to :location
      t.string :name, :limit => 128, :null => false
      t.string :profile_name, :limit => 32, :null => false
      t.integer :moxie, :null => false, :default => 0
      t.integer :funds, :null => false, :default => 0
      t.integer :level, :null => false, :default => 1
      t.integer :experience, :null => false, :default => 0
      t.integer :skill_points, :null => false, :default => 0
      t.integer :wounds, :null => false, :default => 0
      t.integer :madness, :null => false, :default => 0
      t.integer :psychoses_count, :default => 0      
      t.timestamp :created_at
      t.timestamp :last_income_at
      t.timestamp :last_recovery_at
    end
    add_index :investigators, :user_id
    add_index :investigators, :location_id
    
    create_table :characters do |t|
      t.belongs_to :user, :null => false
      t.belongs_to :location, :null => false
      t.string :name, :limit => 128, :null => false
      t.string :profession, :limit => 64, :null => false
      t.string :biography, :limit => 1024
    end
    add_index :characters, :user_id
    add_index :characters, :location_id
    
    create_table :character_skills do |t|
      t.belongs_to :character, :null => false
      t.belongs_to :skill, :null => false
      t.string :skill_name, :null => false, :limit => 32
      t.integer :skill_level, :null => false, :default => 0
    end
    add_index :character_skills, :character_id
    add_index :character_skills, [:character_id, :skill_id], :unique => true
    
    create_table :characters_plots, :id => false do |t|
      t.belongs_to :character, :null => false
      t.belongs_to :plot, :null => false
    end
    add_index :characters_plots, [:character_id,:plot_id], :unique => true    
    
    create_table :contacts do |t|
      t.belongs_to :character, :null => false
      t.belongs_to :investigator, :null => false
      t.string :name, :limit => 128, :null => false
      t.integer :favor_count, :null => false, :default => 0
      t.timestamp :created_at
      t.timestamp :last_entreated_at
    end
    add_index :contacts, [:character_id, :investigator_id], :unique => true
    add_index :contacts, :favor_count
    
    create_table :characters_profiles, :id => false do |t|
      t.belongs_to :character, :null => false
      t.belongs_to :profile, :null => false
    end    
    add_index :characters_profiles, [:character_id, :profile_id], :unique => true
    
    create_table :stats do |t|
      t.belongs_to :investigator, :null => false
      t.belongs_to :skill, :null => false
      t.string :skill_name, :limit => 32, :null => false
      t.integer :skill_level, :null => false, :default => 0
      t.integer :skill_points, :null => false, :default => 0
    end
    add_index :stats, [:investigator_id, :skill_level]
    add_index :stats, :investigator_id
    add_index :stats, :skill_id
    add_index :stats, :skill_level
    
    create_table :allies do |t|
      t.belongs_to :investigator, :null => false
      t.belongs_to :ally, :null => false
      t.string :name, :limit => 128, :null => false
    end
    add_index :allies, [:investigator_id,:ally_id], :unique => true
    add_index :allies, :ally_id
    
    create_table :monsters do |t|
      t.string :name, :limit => 256, :null => false
      t.string :description, :limit => 512, :null => false, :default => ''
      t.string :kind, :limit => 32, :null => false
      t.integer :attacks, :null => false, :default => 1
      t.integer :power, :null => false, :default => 1
      t.integer :madness, :null => false, :default => 0
      t.integer :defense, :null => false, :default => 1
      t.integer :bounty
      t.integer :level, :null => false, :default => 1
    end
    add_index :monsters, :kind
    add_index :monsters, :level
    
    create_table :combats do |t|
      t.belongs_to :monster, :null => false
      t.belongs_to :investigator, :null => false
      t.belongs_to :assignment
      t.belongs_to :weapon
      t.string :result, :limit => 16, :null => false
      t.string :logs, :limit => 16384, :null => false
      t.integer :wounds, :null => false
      t.timestamp :created_at
    end
    add_index :combats, [:investigator_id, :assignment_id], :unique => true
    add_index :combats, :monster_id
    add_index :combats, :assignment_id
    
    create_table :plots do |t|
      t.string :title, :limit => 64, :null => false
      t.string :subtitle, :limit => 256
      t.string :description, :limit => 2048
      t.integer :duration, :null => false
      t.integer :level, :null => false, :default => 1
      t.integer :madness, :null => false, :default => 0
    end
    add_index :plots, :level
    
    create_table :solutions do |t|
      t.belongs_to :plot, :null => false
      t.string :title, :limit => 128, :null => false
      t.string :description, :limit => 512, :null => false
      t.string :kind, :limit => 32, :null => false
    end
    add_index :solutions, :plot_id
    add_index :solutions, :kind
    
    create_table :intrigues do |t|
      t.belongs_to :plot, :null => false
      t.belongs_to :challenge, :limit => 32, :null => false
      t.integer :ordinal, :null => false, :default => 0
      t.integer :difficulty, :null => false, :default => 1
      t.string :title, :limit => 128, :null => false
    end
    add_index :intrigues, [:plot_id,:ordinal]
    
    create_table :threats do |t| 
      t.belongs_to :plot, :null => false
      t.belongs_to :intrigue, :null => false
      t.belongs_to :monster, :null => false
      t.string :name, :limit => 256, :null => false
    end
    add_index :threats, :plot_id
    add_index :threats, :intrigue_id
    add_index :threats, :monster_id
    
    create_table :prerequisites do |t|
      t.belongs_to :plot, :null => false
      t.string :requirement_type, :null => false
      t.string :requirement_name, :null => false
      t.integer :requirement_id, :null => false
    end
    add_index :prerequisites, :plot_id
    add_index :prerequisites, :requirement_type
    add_index :prerequisites, :requirement_id
    
    create_table :rewards do |t|
      t.belongs_to :plot, :null => false
      t.string :reward_type, :null => false
      t.string :reward_name, :null => false
      t.integer :reward_id, :null => false
    end    
    add_index :rewards, :plot_id
    add_index :rewards, :reward_type
    add_index :rewards, :reward_id
    
    create_table :plot_threads do |t|
      t.belongs_to :investigator, :null => false
      t.belongs_to :plot, :null => false
      t.belongs_to :solution
      t.integer :investigations_count, :default => 0
      t.string :status, :null => false
      t.string :plot_title, :limit => 64, :null => false
      t.timestamp :created_at
    end
    add_index :plot_threads, [:investigator_id,:plot_id], :unique => true
    add_index :plot_threads, :status
    add_index :plot_threads, :created_at
    
    create_table :investigations do |t|
      t.belongs_to :plot_thread, :null => false
      t.string :plot_title, :limit => 64, :null => false
      t.string :status, :null => false
      t.integer :duration, :null => false
      t.integer :moxie_speed, :null => false, :default => 0
      t.integer :moxie_challenge, :null => false, :default => 0
      t.timestamps :created_at
      t.timestamp :finished_at
    end
    add_index :investigations, [:plot_thread_id,:created_at]
    add_index :investigations, :status
    
    create_table :assignments do |t|
      t.belongs_to :investigation, :null => false
      t.belongs_to :investigator, :null => false
      t.belongs_to :intrigue, :null => false
      t.belongs_to :ally
      t.belongs_to :contact
      t.string :status, :null => false
      t.string :result, :limit => 16
      t.string :logs, :limit => 256
      t.string :facebook_request_id, :limit => 32
      t.integer :challenge_target
      t.integer :challenge_score
    end    
    add_index :assignments, [:investigator_id,:investigation_id,:intrigue_id], :unique => true, :name => 'index_assignments_on_instance'
    add_index :assignments, :ally_id
    add_index :assignments, :contact_id
    add_index :assignments, :investigation_id
    add_index :assignments, :status
    
    create_table :items do |t|
      t.belongs_to :location
      t.string :name, :limit => 128, :null => false
      t.string :description, :limit => 256, :null => false, :default => ''
      t.string :kind, :limit => 32, :null => false
      t.integer :price, :null => false, :default => 0
      t.integer :power, :default => nil
      t.integer :uses_count
    end
    add_index :items, :location_id
    add_index :items, :kind
    add_index :items, :name
    add_index :items, :price
    add_index :items, :uses_count
    
    create_table :possessions do |t|
      t.belongs_to :investigator, :null => false
      t.belongs_to :item, :null => false
      t.string :item_name, :limit => 128, :null => false
      t.integer :uses_count
      t.timestamp :created_at
      t.timestamp :last_used_at
    end  
    add_index :possessions, [:investigator_id,:uses_count]
    add_index :possessions, :uses_count
    add_index :possessions, :item_name
    add_index :possessions, :item_id
    add_index :possessions, :last_used_at    
    
    create_table :weapons do |t|
      t.string :name, :limit => 128, :null => false
      t.string :description, :limit => 256, :null => false, :default => ''
      t.string :kind, :limit => 32, :null => false
      t.integer :attacks, :null => false, :default => 1
      t.integer :power, :null => false, :default => 1
      t.integer :price, :null => false, :default => 0
    end    
    add_index :weapons, :kind
    add_index :weapons, :power
    add_index :weapons, :name
    
    create_table :armaments do |t|
      t.belongs_to :investigator, :null => false
      t.belongs_to :weapon, :null => false
      t.string :weapon_name, :limit => 128, :null => false
      t.timestamps
    end
    add_index :armaments, [:investigator_id,:weapon_id], :unique => true
    
    create_table :locations do |t|
      t.string :name, :limit => 256, :null => false
      t.string :zone, :limit => 32, :null => false
      t.string :description, :limit => 512
      t.belongs_to :location
    end
    add_index :locations, :location_id
    
    create_table :locations_plots, :id => false do |t|
      t.belongs_to :location, :null => false
      t.belongs_to :plot, :null => false
    end
    add_index :locations_plots, [:location_id,:plot_id], :unique => true
    
    create_table :denizens do |t|
      t.belongs_to :location, :null => false
      t.belongs_to :monster, :null => false
    end
    add_index :denizens, :location_id
    add_index :denizens, :monster_id

    create_table :transits do |t|
      t.belongs_to :origin, :null => false
      t.belongs_to :destination, :null => false
      t.string :mode, :limit => 32, :null => false
      t.integer :price, :null => false
    end
    add_index :transits, [:origin_id]
    add_index :transits, [:destination_id]
    
    create_table :spells do |t|
      t.belongs_to :target
      t.string :name, :limit => 256, :null => false
      t.string :kind, :limit => 32, :null => false
      t.string :effect, :limit => 256, :null => false
      t.string :description, :limit => 512, :null => false
      t.integer :power, :null => false
      t.integer :duration, :null => false
      t.integer :time_cost, :default => 0, :null => false
      t.integer :wound_cost, :default => 0, :null => false
      t.integer :madness_cost, :default => 0, :null => false
    end    
    add_index :spells, [:kind]
    add_index :spells, [:effect]
    
    create_table :grimoires do |t|
      t.string :name, :limit => 256, :null => false
      t.string :description, :limit => 512
      t.integer :madness_cost, :default => 0, :null => false
    end
    
    create_table :grimoires_spells, :id => false do |t|
      t.belongs_to :grimoire, :null => false
      t.belongs_to :spell, :null => false
    end
    add_index :grimoires_spells, [:grimoire_id,:spell_id], :unique => true
    
    create_table :spellbooks do |t|
      t.belongs_to :investigator, :null => false
      t.belongs_to :grimoire, :null => false
      t.string :name, :limit => 256, :null => false
      t.boolean :read, :null => false, :default => false
      t.timestamp :created_at
    end    
    add_index :spellbooks, [:investigator_id,:grimoire_id], :unique => true
    add_index :spellbooks, :grimoire_id
    add_index :spellbooks, :read
    
    create_table :castings do |t|
      t.belongs_to :investigator, :null => false
      t.belongs_to :spell, :null => false
      t.string :name, :limit => 256, :null => false
      t.integer :moxie_speed, :null => false, :default => 0
      t.timestamp :created_at
      t.timestamp :completed_at
      t.timestamp :ended_at
    end
    add_index :castings, :investigator_id
    add_index :castings, :spell_id
    add_index :castings, :ended_at
    add_index :castings, [:completed_at,:ended_at]
    
    create_table :social_functions do |t|    
      t.string :name, :limit => 128, :null => false
      t.string :kind, :limit => 32, :null => false
      t.string :description, :limit => 512, :null => false
      t.string :invitation, :limit => 512, :null => false
      t.string :cooperation, :limit => 128, :null => false
      t.string :defection, :limit => 128, :null => false
    end
    add_index :social_functions, :kind
    
    create_table :socials do |t|
      t.belongs_to :social_function, :null => false
      t.belongs_to :investigator, :null => false
      t.string :name, :limit => 128, :null => false
      t.string :reward, :limit => 256
      t.string :logs, :limit => 16384, :null => false
      t.timestamp :appointment_at, :null => false
      t.timestamp :created_at
      t.timestamp :hosted_at
    end
    add_index :socials, :social_function_id
    add_index :socials, :investigator_id
    add_index :socials, :hosted_at
    add_index :socials, [:created_at, :appointment_at]
    add_index :socials, [:appointment_at, :created_at]
    
    create_table :guests do |t|
      t.belongs_to :social
      t.belongs_to :investigator
      t.string :status, :limit => 32, :null => false
      t.string :reward, :limit => 256
      t.timestamp :created_at
    end
    add_index :guests, [:investigator_id, :social_id], :unique => true
    add_index :guests, :social_id
    add_index :guests, :status
    
    create_table :insanities do |t|
      t.string :name, :limit => 256, :null => false
      t.string :description, :limit => 512
      t.belongs_to :skill, :null => false
    end
    add_index :insanities, :skill_id
    
    create_table :psychoses do |t|
      t.belongs_to :insanity
      t.belongs_to :investigator
      t.string :name, :limit => 256, :null => false
      t.integer :severity, :default => 1, :null => false
      t.integer :next_treatment_bonus
      t.timestamp :created_at
      t.timestamp :next_treatment_at
    end  
    add_index :psychoses, :insanity_id
    add_index :psychoses, :investigator_id
    add_index :psychoses, :next_treatment_at
    
    create_table :introductions do |t|
      t.belongs_to :character, :null => false
      t.belongs_to :investigator, :null => false
      t.belongs_to :introducer
      t.belongs_to :plot
      t.string :status, :limit => 32, :null => false
      t.string :message, :limit => 1024, :null => false
      t.timestamps
    end
    add_index :introductions, :investigator_id
    add_index :introductions, :character_id
    add_index :introductions, [:investigator_id,:status,:created_at], :name => "index_introductions_on_investigator"
    add_index :introductions, [:introducer_id,:status,:created_at], :name => "index_introductions_on_introducer"
    add_index :introductions, :status
    add_index :introductions, :plot_id
    
    create_table :activities do |t|
      t.string :name, :limit => 64, :null => false
      t.string :namespace, :limit => 32, :null => false
      t.string :message, :null => false, :limit => 1024
      t.string :dashboard_news, :limit => 2048
      t.boolean :passive, :null => false
    end    
    add_index :activities, :namespace, :unique => true
    add_index :activities, :passive
    
    create_table :investigator_activities do |t|
      t.belongs_to :activity, :null => false
      t.belongs_to :investigator, :null => false
      t.belongs_to :actor, :polymorphic => true
      t.belongs_to :object, :polymorphic => true
      t.belongs_to :subject, :polymorphic => true
      t.string :message, :null => false, :limit => 1024
      t.boolean :read, :null => false, :default => false
      t.timestamp :created_at
    end    
    add_index :investigator_activities, :activity_id
    add_index :investigator_activities, [:actor_id,:actor_type]
    add_index :investigator_activities, [:object_id,:object_type]
    add_index :investigator_activities, [:subject_id,:subject_type]
    add_index :investigator_activities, [:investigator_id,:read]
    add_index :investigator_activities, :created_at
    
    create_table :effecacies do |t|
      t.string :namespace, :limit => 32, :null => false
    end
    add_index :effecacies, :namespace, :unique => true
    
    create_table :effects do |t|
      t.belongs_to :effecacy, :null => false
      t.belongs_to :trigger, :null => false, :polymorphic => true
      t.belongs_to :target, :polymorphic => true
      t.string :target_name, :limit => 256, :null => false
      t.string :name, :limit => 256, :null => false
      t.string :description, :limit => 1024
      t.integer :duration
      t.integer :power
    end
    add_index :effects, :effecacy_id
    add_index :effects, [:trigger_id,:trigger_type]
    add_index :effects, [:target_id,:target_type]
    
    create_table :effections do |t|
      t.belongs_to :effect, :null => false
      t.belongs_to :investigator, :null => false
      t.timestamp :begins_at, :null => false
      t.timestamp :ends_at, :null => false
      t.timestamp :created_at
    end
    add_index :effections, [:investigator_id,:begins_at,:ends_at]
    add_index :effections, :effect_id
    
    create_table :tasks do |t|
      t.belongs_to :skill, :null => false
      t.string :name, :null => false
      t.string :task_type, :null => false
      t.string :description, :null => false, :limit => 512
    end    
    add_index :tasks, :skill_id
    add_index :tasks, :task_type
    
    create_table :taskings do |t|
      t.belongs_to :task
      t.belongs_to :owner, :polymorphic => true      
      t.string :owner_name, :null => false
      t.integer :difficulty, :null => false
      t.integer :level, :null => false, :default => 1
      t.string :reward_name, :null => false
      t.integer :reward_id, :null => false
    end
    add_index :taskings, :task_id
    add_index :taskings, [:owner_id,:owner_type]
    add_index :taskings, :level
    add_index :taskings, :reward_id
    
    create_table :efforts do |t|
      t.belongs_to :investigator, :null => false
      t.belongs_to :tasking, :null => false
      t.integer :challenge_target
      t.integer :challenge_score
      t.timestamp :created_at
    end    
    add_index :efforts, :investigator_id
    add_index :efforts, :tasking_id
  end

  def self.down
    drop_table :efforts
    drop_table :taskings
    drop_table :tasks
    drop_table :effections
    drop_table :effects
    drop_table :effecacies
    drop_table :investigator_activities
    drop_table :activities
    drop_table :introductions
    drop_table :psychoses
    drop_table :insanities
    drop_table :guests
    drop_table :socials
    drop_table :social_functions
    drop_table :castings
    drop_table :grimoires_spells
    drop_table :grimoires
    drop_table :spells
    drop_table :transits
    drop_table :locations_plots
    drop_table :locations
    drop_table :armaments
    drop_table :weapons
    drop_table :possessions
    drop_table :items
    drop_table :assignments
    drop_table :contacts
    drop_table :characters_plots
    drop_table :character_skills
    drop_table :characters
    drop_table :investigations
    drop_table :plot_threads
    drop_table :prerequisites
    drop_table :threats
    drop_table :intrigues
    drop_table :plots
    drop_table :combats
    drop_table :monsters
    drop_table :allies
    drop_table :investigators
    drop_table :profiles
    drop_table :sessions
    drop_table :users
  end  
end