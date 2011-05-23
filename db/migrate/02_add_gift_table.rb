class AddGiftTable < ActiveRecord::Migration
  def self.up
    create_table :gifts do |t|
      t.belongs_to :investigator, :null => false
      t.belongs_to :sender, :null => false
      t.string :sender_name, :limit => 512, :null => false
      t.string :gift_id, :null => false
      t.string :gift_type, :limit => 256, :null => false
      t.string :gift_name, :limit => 256, :null => false
      t.timestamp :created_at
    end
    add_index :gifts, :investigator_id
    add_index :gifts, :sender_id
    add_index :gifts, [:gift_type,:gift_id]    
  end
    
  def self.down
    drop_table :gifts
  end
end
        