class CreateCustomerStatus < ActiveRecord::Migration[5.2]
    create_table :customer_statuses do |t|
      enable_extension 'citext'
      t.integer :status,index: true, null: false
      t.integer :duration
      t.boolean :is_deleted, null: false, default: 0
      t.timestamps null: false
      t.integer :customer_id, index: true
      t.integer :location_id, index: true
      # t.integer :customer_journal_item_id
      # t.references :customer, index: true, foreign_key: true, null: false
      # t.references :customer_journal_item, foreign_key: true, null: false
      # t.jsonb :customer, null: false, default: '{}'
  end

  def self.down
    drop_table :customer_statuses
  end
end
