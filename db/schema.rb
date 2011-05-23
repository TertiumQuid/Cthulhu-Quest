# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 2) do

  create_table "activities", :force => true do |t|
    t.string  "name",           :limit => 64,   :null => false
    t.string  "namespace",      :limit => 32,   :null => false
    t.string  "message",        :limit => 1024, :null => false
    t.string  "dashboard_news", :limit => 2048
    t.boolean "passive",                        :null => false
  end

  add_index "activities", ["namespace"], :name => "index_activities_on_namespace", :unique => true
  add_index "activities", ["passive"], :name => "index_activities_on_passive"

  create_table "allies", :force => true do |t|
    t.integer "investigator_id",                :null => false
    t.integer "ally_id",                        :null => false
    t.string  "name",            :limit => 128, :null => false
  end

  add_index "allies", ["ally_id"], :name => "index_allies_on_ally_id"
  add_index "allies", ["investigator_id", "ally_id"], :name => "index_allies_on_investigator_id_and_ally_id", :unique => true

  create_table "armaments", :force => true do |t|
    t.integer  "investigator_id",                :null => false
    t.integer  "weapon_id",                      :null => false
    t.string   "weapon_name",     :limit => 128, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "armaments", ["investigator_id", "weapon_id"], :name => "index_armaments_on_investigator_id_and_weapon_id", :unique => true

  create_table "assignments", :force => true do |t|
    t.integer "investigation_id",                   :null => false
    t.integer "investigator_id",                    :null => false
    t.integer "intrigue_id",                        :null => false
    t.integer "ally_id"
    t.integer "contact_id"
    t.string  "status",                             :null => false
    t.string  "result",              :limit => 16
    t.string  "logs",                :limit => 256
    t.string  "facebook_request_id", :limit => 32
    t.integer "challenge_target"
    t.integer "challenge_score"
  end

  add_index "assignments", ["ally_id"], :name => "index_assignments_on_ally_id"
  add_index "assignments", ["contact_id"], :name => "index_assignments_on_contact_id"
  add_index "assignments", ["investigation_id"], :name => "index_assignments_on_investigation_id"
  add_index "assignments", ["investigator_id", "investigation_id", "intrigue_id"], :name => "index_assignments_on_instance", :unique => true
  add_index "assignments", ["status"], :name => "index_assignments_on_status"

  create_table "castings", :force => true do |t|
    t.integer  "investigator_id",                               :null => false
    t.integer  "spell_id",                                      :null => false
    t.string   "name",            :limit => 256,                :null => false
    t.integer  "moxie_speed",                    :default => 0, :null => false
    t.datetime "created_at"
    t.datetime "completed_at"
    t.datetime "ended_at"
  end

  add_index "castings", ["completed_at", "ended_at"], :name => "index_castings_on_completed_at_and_ended_at"
  add_index "castings", ["ended_at"], :name => "index_castings_on_ended_at"
  add_index "castings", ["investigator_id"], :name => "index_castings_on_investigator_id"
  add_index "castings", ["spell_id"], :name => "index_castings_on_spell_id"

  create_table "character_skills", :force => true do |t|
    t.integer "character_id",                              :null => false
    t.integer "skill_id",                                  :null => false
    t.string  "skill_name",   :limit => 32,                :null => false
    t.integer "skill_level",                :default => 0, :null => false
  end

  add_index "character_skills", ["character_id", "skill_id"], :name => "index_character_skills_on_character_id_and_skill_id", :unique => true
  add_index "character_skills", ["character_id"], :name => "index_character_skills_on_character_id"

  create_table "characters", :force => true do |t|
    t.integer "user_id",                     :null => false
    t.integer "location_id",                 :null => false
    t.string  "name",        :limit => 128,  :null => false
    t.string  "profession",  :limit => 64,   :null => false
    t.string  "biography",   :limit => 1024
  end

  add_index "characters", ["location_id"], :name => "index_characters_on_location_id"
  add_index "characters", ["user_id"], :name => "index_characters_on_user_id"

  create_table "characters_plots", :id => false, :force => true do |t|
    t.integer "character_id", :null => false
    t.integer "plot_id",      :null => false
  end

  add_index "characters_plots", ["character_id", "plot_id"], :name => "index_characters_plots_on_character_id_and_plot_id", :unique => true

  create_table "characters_profiles", :id => false, :force => true do |t|
    t.integer "character_id", :null => false
    t.integer "profile_id",   :null => false
  end

  add_index "characters_profiles", ["character_id", "profile_id"], :name => "index_characters_profiles_on_character_id_and_profile_id", :unique => true

  create_table "combats", :force => true do |t|
    t.integer  "monster_id",                       :null => false
    t.integer  "investigator_id",                  :null => false
    t.integer  "assignment_id"
    t.integer  "weapon_id"
    t.string   "result",          :limit => 16,    :null => false
    t.string   "logs",            :limit => 16384, :null => false
    t.integer  "wounds",                           :null => false
    t.datetime "created_at"
  end

  add_index "combats", ["assignment_id"], :name => "index_combats_on_assignment_id"
  add_index "combats", ["investigator_id", "assignment_id"], :name => "index_combats_on_investigator_id_and_assignment_id", :unique => true
  add_index "combats", ["monster_id"], :name => "index_combats_on_monster_id"

  create_table "contacts", :force => true do |t|
    t.integer  "character_id",                                    :null => false
    t.integer  "investigator_id",                                 :null => false
    t.string   "name",              :limit => 128,                :null => false
    t.integer  "favor_count",                      :default => 0, :null => false
    t.datetime "created_at"
    t.datetime "last_entreated_at"
  end

  add_index "contacts", ["character_id", "investigator_id"], :name => "index_contacts_on_character_id_and_investigator_id", :unique => true
  add_index "contacts", ["favor_count"], :name => "index_contacts_on_favor_count"

  create_table "denizens", :force => true do |t|
    t.integer "location_id", :null => false
    t.integer "monster_id",  :null => false
  end

  add_index "denizens", ["location_id"], :name => "index_denizens_on_location_id"
  add_index "denizens", ["monster_id"], :name => "index_denizens_on_monster_id"

  create_table "effecacies", :force => true do |t|
    t.string "namespace", :limit => 32, :null => false
  end

  add_index "effecacies", ["namespace"], :name => "index_effecacies_on_namespace", :unique => true

  create_table "effections", :force => true do |t|
    t.integer  "effect_id",       :null => false
    t.integer  "investigator_id", :null => false
    t.datetime "begins_at",       :null => false
    t.datetime "ends_at",         :null => false
    t.datetime "created_at"
  end

  add_index "effections", ["effect_id"], :name => "index_effections_on_effect_id"
  add_index "effections", ["investigator_id", "begins_at", "ends_at"], :name => "index_effections_on_investigator_id_and_begins_at_and_ends_at"

  create_table "effects", :force => true do |t|
    t.integer "effecacy_id",                  :null => false
    t.integer "trigger_id",                   :null => false
    t.string  "trigger_type",                 :null => false
    t.integer "target_id"
    t.string  "target_type"
    t.string  "target_name",  :limit => 256,  :null => false
    t.string  "name",         :limit => 256,  :null => false
    t.string  "description",  :limit => 1024
    t.integer "duration"
    t.integer "power"
  end

  add_index "effects", ["effecacy_id"], :name => "index_effects_on_effecacy_id"
  add_index "effects", ["target_id", "target_type"], :name => "index_effects_on_target_id_and_target_type"
  add_index "effects", ["trigger_id", "trigger_type"], :name => "index_effects_on_trigger_id_and_trigger_type"

  create_table "efforts", :force => true do |t|
    t.integer  "investigator_id",  :null => false
    t.integer  "tasking_id",       :null => false
    t.integer  "challenge_target"
    t.integer  "challenge_score"
    t.datetime "created_at"
  end

  add_index "efforts", ["investigator_id"], :name => "index_efforts_on_investigator_id"
  add_index "efforts", ["tasking_id"], :name => "index_efforts_on_tasking_id"

  create_table "gifts", :force => true do |t|
    t.integer  "investigator_id",                :null => false
    t.integer  "sender_id",                      :null => false
    t.string   "sender_name",     :limit => 512, :null => false
    t.string   "gift_id",                        :null => false
    t.string   "gift_type",       :limit => 256, :null => false
    t.string   "gift_name",       :limit => 256, :null => false
    t.datetime "created_at"
  end

  add_index "gifts", ["gift_type", "gift_id"], :name => "index_gifts_on_gift_type_and_gift_id"
  add_index "gifts", ["investigator_id"], :name => "index_gifts_on_investigator_id"
  add_index "gifts", ["sender_id"], :name => "index_gifts_on_sender_id"

  create_table "grimoires", :force => true do |t|
    t.string  "name",         :limit => 256,                :null => false
    t.string  "description",  :limit => 512
    t.integer "madness_cost",                :default => 0, :null => false
  end

  create_table "grimoires_spells", :id => false, :force => true do |t|
    t.integer "grimoire_id", :null => false
    t.integer "spell_id",    :null => false
  end

  add_index "grimoires_spells", ["grimoire_id", "spell_id"], :name => "index_grimoires_spells_on_grimoire_id_and_spell_id", :unique => true

  create_table "guests", :force => true do |t|
    t.integer  "social_id"
    t.integer  "investigator_id"
    t.string   "status",          :limit => 32,  :null => false
    t.string   "reward",          :limit => 256
    t.datetime "created_at"
  end

  add_index "guests", ["investigator_id", "social_id"], :name => "index_guests_on_investigator_id_and_social_id", :unique => true
  add_index "guests", ["social_id"], :name => "index_guests_on_social_id"
  add_index "guests", ["status"], :name => "index_guests_on_status"

  create_table "insanities", :force => true do |t|
    t.string  "name",        :limit => 256, :null => false
    t.string  "description", :limit => 512
    t.integer "skill_id",                   :null => false
  end

  add_index "insanities", ["skill_id"], :name => "index_insanities_on_skill_id"

  create_table "intrigues", :force => true do |t|
    t.integer "plot_id",                                    :null => false
    t.integer "challenge_id",                               :null => false
    t.integer "ordinal",                     :default => 0, :null => false
    t.integer "difficulty",                  :default => 1, :null => false
    t.string  "title",        :limit => 128,                :null => false
  end

  add_index "intrigues", ["plot_id", "ordinal"], :name => "index_intrigues_on_plot_id_and_ordinal"

  create_table "introductions", :force => true do |t|
    t.integer  "character_id",                    :null => false
    t.integer  "investigator_id",                 :null => false
    t.integer  "introducer_id"
    t.integer  "plot_id"
    t.string   "status",          :limit => 32,   :null => false
    t.string   "message",         :limit => 1024, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "introductions", ["character_id"], :name => "index_introductions_on_character_id"
  add_index "introductions", ["introducer_id", "status", "created_at"], :name => "index_introductions_on_introducer"
  add_index "introductions", ["investigator_id", "status", "created_at"], :name => "index_introductions_on_investigator"
  add_index "introductions", ["investigator_id"], :name => "index_introductions_on_investigator_id"
  add_index "introductions", ["plot_id"], :name => "index_introductions_on_plot_id"
  add_index "introductions", ["status"], :name => "index_introductions_on_status"

  create_table "investigations", :force => true do |t|
    t.integer  "plot_thread_id",                               :null => false
    t.string   "plot_title",      :limit => 64,                :null => false
    t.string   "status",                                       :null => false
    t.integer  "duration",                                     :null => false
    t.integer  "moxie_speed",                   :default => 0, :null => false
    t.integer  "moxie_challenge",               :default => 0, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "finished_at"
  end

  add_index "investigations", ["plot_thread_id", "created_at"], :name => "index_investigations_on_plot_thread_id_and_created_at"
  add_index "investigations", ["status"], :name => "index_investigations_on_status"

  create_table "investigator_activities", :force => true do |t|
    t.integer  "activity_id",                                        :null => false
    t.integer  "investigator_id",                                    :null => false
    t.integer  "actor_id"
    t.string   "actor_type"
    t.integer  "object_id"
    t.string   "object_type"
    t.integer  "subject_id"
    t.string   "subject_type"
    t.string   "message",         :limit => 1024,                    :null => false
    t.boolean  "read",                            :default => false, :null => false
    t.datetime "created_at"
  end

  add_index "investigator_activities", ["activity_id"], :name => "index_investigator_activities_on_activity_id"
  add_index "investigator_activities", ["actor_id", "actor_type"], :name => "index_investigator_activities_on_actor_id_and_actor_type"
  add_index "investigator_activities", ["investigator_id", "activity_id", "created_at"], :name => "index_investigator_activities_on_created_at"
  add_index "investigator_activities", ["investigator_id", "read"], :name => "index_investigator_activities_on_investigator_id_and_read"
  add_index "investigator_activities", ["object_id", "object_type"], :name => "index_investigator_activities_on_object_id_and_object_type"
  add_index "investigator_activities", ["subject_id", "subject_type"], :name => "index_investigator_activities_on_subject_id_and_subject_type"

  create_table "investigators", :force => true do |t|
    t.integer  "profile_id",                                     :null => false
    t.integer  "user_id"
    t.integer  "armed_id"
    t.integer  "location_id"
    t.string   "name",             :limit => 128,                :null => false
    t.string   "profile_name",     :limit => 32,                 :null => false
    t.integer  "moxie",                           :default => 0, :null => false
    t.integer  "funds",                           :default => 0, :null => false
    t.integer  "level",                           :default => 1, :null => false
    t.integer  "experience",                      :default => 0, :null => false
    t.integer  "skill_points",                    :default => 0, :null => false
    t.integer  "wounds",                          :default => 0, :null => false
    t.integer  "madness",                         :default => 0, :null => false
    t.integer  "psychoses_count",                 :default => 0
    t.datetime "created_at"
    t.datetime "last_income_at"
    t.datetime "last_recovery_at"
  end

  add_index "investigators", ["location_id"], :name => "index_investigators_on_location_id"
  add_index "investigators", ["user_id"], :name => "index_investigators_on_user_id"

  create_table "items", :force => true do |t|
    t.integer "location_id"
    t.string  "name",        :limit => 128,                 :null => false
    t.string  "description", :limit => 256, :default => "", :null => false
    t.string  "kind",        :limit => 32,                  :null => false
    t.integer "price",                      :default => 0,  :null => false
    t.integer "power"
    t.integer "uses_count"
  end

  add_index "items", ["kind"], :name => "index_items_on_kind"
  add_index "items", ["location_id"], :name => "index_items_on_location_id"
  add_index "items", ["name"], :name => "index_items_on_name"
  add_index "items", ["price"], :name => "index_items_on_price"
  add_index "items", ["uses_count"], :name => "index_items_on_uses_count"

  create_table "locations", :force => true do |t|
    t.string  "name",        :limit => 256, :null => false
    t.string  "zone",        :limit => 32,  :null => false
    t.string  "description", :limit => 512
    t.integer "location_id"
  end

  add_index "locations", ["location_id"], :name => "index_locations_on_location_id"

  create_table "locations_plots", :id => false, :force => true do |t|
    t.integer "location_id", :null => false
    t.integer "plot_id",     :null => false
  end

  add_index "locations_plots", ["location_id", "plot_id"], :name => "index_locations_plots_on_location_id_and_plot_id", :unique => true

  create_table "monsters", :force => true do |t|
    t.string  "name",        :limit => 256,                 :null => false
    t.string  "description", :limit => 512, :default => "", :null => false
    t.string  "kind",        :limit => 32,                  :null => false
    t.integer "attacks",                    :default => 1,  :null => false
    t.integer "power",                      :default => 1,  :null => false
    t.integer "madness",                    :default => 0,  :null => false
    t.integer "defense",                    :default => 1,  :null => false
    t.integer "bounty"
    t.integer "level",                      :default => 1,  :null => false
  end

  add_index "monsters", ["kind"], :name => "index_monsters_on_kind"
  add_index "monsters", ["level"], :name => "index_monsters_on_level"

  create_table "plot_threads", :force => true do |t|
    t.integer  "investigator_id",                                   :null => false
    t.integer  "plot_id",                                           :null => false
    t.integer  "solution_id"
    t.integer  "investigations_count",               :default => 0
    t.string   "status",                                            :null => false
    t.string   "plot_title",           :limit => 64,                :null => false
    t.datetime "created_at"
  end

  add_index "plot_threads", ["created_at"], :name => "index_plot_threads_on_created_at"
  add_index "plot_threads", ["investigator_id", "plot_id"], :name => "index_plot_threads_on_investigator_id_and_plot_id", :unique => true
  add_index "plot_threads", ["status"], :name => "index_plot_threads_on_status"

  create_table "plots", :force => true do |t|
    t.string  "title",       :limit => 64,                  :null => false
    t.string  "subtitle",    :limit => 256
    t.string  "description", :limit => 2048
    t.integer "duration",                                   :null => false
    t.integer "level",                       :default => 1, :null => false
    t.integer "madness",                     :default => 0, :null => false
  end

  add_index "plots", ["level"], :name => "index_plots_on_level"

  create_table "possessions", :force => true do |t|
    t.integer  "investigator_id",                :null => false
    t.integer  "item_id",                        :null => false
    t.string   "item_name",       :limit => 128, :null => false
    t.integer  "uses_count"
    t.datetime "created_at"
    t.datetime "last_used_at"
  end

  add_index "possessions", ["investigator_id", "uses_count"], :name => "index_possessions_on_investigator_id_and_uses_count"
  add_index "possessions", ["item_id"], :name => "index_possessions_on_item_id"
  add_index "possessions", ["item_name"], :name => "index_possessions_on_item_name"
  add_index "possessions", ["last_used_at"], :name => "index_possessions_on_last_used_at"
  add_index "possessions", ["uses_count"], :name => "index_possessions_on_uses_count"

  create_table "prerequisites", :force => true do |t|
    t.integer "plot_id",          :null => false
    t.string  "requirement_type", :null => false
    t.string  "requirement_name", :null => false
    t.integer "requirement_id",   :null => false
  end

  add_index "prerequisites", ["plot_id"], :name => "index_prerequisites_on_plot_id"
  add_index "prerequisites", ["requirement_id"], :name => "index_prerequisites_on_requirement_id"
  add_index "prerequisites", ["requirement_type"], :name => "index_prerequisites_on_requirement_type"

  create_table "profile_skills", :force => true do |t|
    t.integer "profile_id",                               :null => false
    t.integer "skill_id",                                 :null => false
    t.string  "skill_name",  :limit => 32,                :null => false
    t.integer "skill_level",               :default => 0, :null => false
  end

  add_index "profile_skills", ["profile_id", "skill_id"], :name => "index_profile_skills_on_profile_id_and_skill_id", :unique => true

  create_table "profiles", :force => true do |t|
    t.string  "name",   :limit => 32
    t.integer "income",               :default => 0, :null => false
  end

  create_table "psychoses", :force => true do |t|
    t.integer  "insanity_id"
    t.integer  "investigator_id"
    t.string   "name",                 :limit => 256,                :null => false
    t.integer  "severity",                            :default => 1, :null => false
    t.integer  "next_treatment_bonus"
    t.datetime "created_at"
    t.datetime "next_treatment_at"
  end

  add_index "psychoses", ["insanity_id"], :name => "index_psychoses_on_insanity_id"
  add_index "psychoses", ["investigator_id"], :name => "index_psychoses_on_investigator_id"
  add_index "psychoses", ["next_treatment_at"], :name => "index_psychoses_on_next_treatment_at"

  create_table "rewards", :force => true do |t|
    t.integer "plot_id",     :null => false
    t.string  "reward_type", :null => false
    t.string  "reward_name", :null => false
    t.integer "reward_id",   :null => false
  end

  add_index "rewards", ["plot_id"], :name => "index_rewards_on_plot_id"
  add_index "rewards", ["reward_id"], :name => "index_rewards_on_reward_id"
  add_index "rewards", ["reward_type"], :name => "index_rewards_on_reward_type"

  create_table "sessions", :force => true do |t|
    t.integer  "user_id"
    t.string   "session_id"
    t.text     "data"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], :name => "index_sessions_on_session_id"
  add_index "sessions", ["user_id"], :name => "index_sessions_on_user_id"

  create_table "skills", :force => true do |t|
    t.string "name", :limit => 32
  end

  create_table "social_functions", :force => true do |t|
    t.string "name",        :limit => 128, :null => false
    t.string "kind",        :limit => 32,  :null => false
    t.string "description", :limit => 512, :null => false
    t.string "invitation",  :limit => 512, :null => false
    t.string "cooperation", :limit => 128, :null => false
    t.string "defection",   :limit => 128, :null => false
  end

  add_index "social_functions", ["kind"], :name => "index_social_functions_on_kind"

  create_table "socials", :force => true do |t|
    t.integer  "social_function_id",                  :null => false
    t.integer  "investigator_id",                     :null => false
    t.string   "name",               :limit => 128,   :null => false
    t.string   "reward",             :limit => 256
    t.string   "logs",               :limit => 16384, :null => false
    t.datetime "appointment_at",                      :null => false
    t.datetime "created_at"
    t.datetime "hosted_at"
  end

  add_index "socials", ["appointment_at", "created_at"], :name => "index_socials_on_appointment_at_and_created_at"
  add_index "socials", ["created_at", "appointment_at"], :name => "index_socials_on_created_at_and_appointment_at"
  add_index "socials", ["hosted_at"], :name => "index_socials_on_hosted_at"
  add_index "socials", ["investigator_id"], :name => "index_socials_on_investigator_id"
  add_index "socials", ["social_function_id"], :name => "index_socials_on_social_function_id"

  create_table "solutions", :force => true do |t|
    t.integer "plot_id",                    :null => false
    t.string  "title",       :limit => 128, :null => false
    t.string  "description", :limit => 512, :null => false
    t.string  "kind",        :limit => 32,  :null => false
  end

  add_index "solutions", ["kind"], :name => "index_solutions_on_kind"
  add_index "solutions", ["plot_id"], :name => "index_solutions_on_plot_id"

  create_table "spellbooks", :force => true do |t|
    t.integer  "investigator_id",                                   :null => false
    t.integer  "grimoire_id",                                       :null => false
    t.string   "name",            :limit => 256,                    :null => false
    t.boolean  "read",                           :default => false, :null => false
    t.datetime "created_at"
  end

  add_index "spellbooks", ["grimoire_id"], :name => "index_spellbooks_on_grimoire_id"
  add_index "spellbooks", ["investigator_id", "grimoire_id"], :name => "index_spellbooks_on_investigator_id_and_grimoire_id", :unique => true
  add_index "spellbooks", ["read"], :name => "index_spellbooks_on_read"

  create_table "spells", :force => true do |t|
    t.integer "target_id"
    t.string  "name",         :limit => 256,                :null => false
    t.string  "kind",         :limit => 32,                 :null => false
    t.string  "effect",       :limit => 256,                :null => false
    t.string  "description",  :limit => 512,                :null => false
    t.integer "power",                                      :null => false
    t.integer "duration",                                   :null => false
    t.integer "time_cost",                   :default => 0, :null => false
    t.integer "wound_cost",                  :default => 0, :null => false
    t.integer "madness_cost",                :default => 0, :null => false
  end

  add_index "spells", ["effect"], :name => "index_spells_on_effect"
  add_index "spells", ["kind"], :name => "index_spells_on_kind"

  create_table "stats", :force => true do |t|
    t.integer "investigator_id",                              :null => false
    t.integer "skill_id",                                     :null => false
    t.string  "skill_name",      :limit => 32,                :null => false
    t.integer "skill_level",                   :default => 0, :null => false
    t.integer "skill_points",                  :default => 0, :null => false
  end

  add_index "stats", ["investigator_id", "skill_level"], :name => "index_stats_on_investigator_id_and_skill_level"
  add_index "stats", ["investigator_id"], :name => "index_stats_on_investigator_id"
  add_index "stats", ["skill_id"], :name => "index_stats_on_skill_id"
  add_index "stats", ["skill_level"], :name => "index_stats_on_skill_level"

  create_table "taskings", :force => true do |t|
    t.integer "task_id"
    t.integer "owner_id"
    t.string  "owner_type"
    t.string  "owner_name",                 :null => false
    t.integer "difficulty",                 :null => false
    t.integer "level",       :default => 1, :null => false
    t.string  "reward_name",                :null => false
    t.integer "reward_id",                  :null => false
  end

  add_index "taskings", ["level"], :name => "index_taskings_on_level"
  add_index "taskings", ["owner_id", "owner_type"], :name => "index_taskings_on_owner_id_and_owner_type"
  add_index "taskings", ["reward_id"], :name => "index_taskings_on_reward_id"
  add_index "taskings", ["task_id"], :name => "index_taskings_on_task_id"

  create_table "tasks", :force => true do |t|
    t.integer "skill_id",                   :null => false
    t.string  "name",                       :null => false
    t.string  "task_type",                  :null => false
    t.string  "description", :limit => 512, :null => false
  end

  add_index "tasks", ["skill_id"], :name => "index_tasks_on_skill_id"
  add_index "tasks", ["task_type"], :name => "index_tasks_on_task_type"

  create_table "threats", :force => true do |t|
    t.integer "plot_id",                    :null => false
    t.integer "intrigue_id",                :null => false
    t.integer "monster_id",                 :null => false
    t.string  "name",        :limit => 256, :null => false
  end

  add_index "threats", ["intrigue_id"], :name => "index_threats_on_intrigue_id"
  add_index "threats", ["monster_id"], :name => "index_threats_on_monster_id"
  add_index "threats", ["plot_id"], :name => "index_threats_on_plot_id"

  create_table "transits", :force => true do |t|
    t.integer "origin_id",                    :null => false
    t.integer "destination_id",               :null => false
    t.string  "mode",           :limit => 32, :null => false
    t.integer "price",                        :null => false
  end

  add_index "transits", ["destination_id"], :name => "index_transits_on_destination_id"
  add_index "transits", ["origin_id"], :name => "index_transits_on_origin_id"

  create_table "users", :force => true do |t|
    t.integer  "investigator_id"
    t.string   "name",                    :limit => 256, :null => false
    t.string   "full_name",               :limit => 512, :null => false
    t.string   "email",                   :limit => 256, :null => false
    t.string   "facebook_id",             :limit => 32
    t.string   "facebook_token",          :limit => 512
    t.string   "nonce",                   :limit => 128
    t.string   "password",                :limit => 32
    t.text     "facebook_friend_ids"
    t.datetime "last_login_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "last_facebook_update_at"
  end

  add_index "users", ["facebook_id"], :name => "index_users_on_facebook_id"
  add_index "users", ["investigator_id"], :name => "index_users_on_investigator_id"

  create_table "weapons", :force => true do |t|
    t.string  "name",        :limit => 128,                 :null => false
    t.string  "description", :limit => 256, :default => "", :null => false
    t.string  "kind",        :limit => 32,                  :null => false
    t.integer "attacks",                    :default => 1,  :null => false
    t.integer "power",                      :default => 1,  :null => false
    t.integer "price",                      :default => 0,  :null => false
  end

  add_index "weapons", ["kind"], :name => "index_weapons_on_kind"
  add_index "weapons", ["name"], :name => "index_weapons_on_name"
  add_index "weapons", ["power"], :name => "index_weapons_on_power"

end
