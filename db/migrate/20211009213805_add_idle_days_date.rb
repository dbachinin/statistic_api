class AddIdleDaysDate < ActiveRecord::Migration[6.1]
  def change
    add_column :customers, :idle_days_date, :datetime
  end
end
