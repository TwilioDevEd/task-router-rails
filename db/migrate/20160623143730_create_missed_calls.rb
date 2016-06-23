class CreateMissedCalls < ActiveRecord::Migration
  def change
    create_table :missed_calls do |t|
      t.string :selected_product
      t.string :phone_number

      t.timestamps null: false
    end
  end
end
