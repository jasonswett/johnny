class CreateEdges < ActiveRecord::Migration[7.1]
  def change
    create_table :edges, id: :uuid do |t|
      t.references :token_1, null: false, foreign_key: { to_table: :tokens }, type: :uuid
      t.references :token_2, null: false, foreign_key: { to_table: :tokens }, type: :uuid
      t.integer :distance, null: false

      t.timestamps
    end

    add_index :edges, [:token_1_id, :token_2_id, :distance], unique: true
  end
end
