class CreateSentences < ActiveRecord::Migration[7.1]
  def change
    create_table :sentences, id: :uuid do |t|
      t.string :value, null: false

      t.timestamps
    end

    add_index :sentences, :value, unique: true
  end
end
