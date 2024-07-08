class CreateTriplets < ActiveRecord::Migration[7.1]
  def change
    create_table :triplets, id: :uuid do |t|
      t.references :token, null: false, foreign_key: true, type: :uuid
      t.string :text, null: false
      t.string :mask, null: false

      t.timestamps
    end
  end
end
