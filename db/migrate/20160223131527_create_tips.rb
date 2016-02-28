class CreateTips < ActiveRecord::Migration
  def change
    create_table :tips do |t|
      t.string :amount
      t.string :user_id

      t.timestamps null: false
    end
  end
end
