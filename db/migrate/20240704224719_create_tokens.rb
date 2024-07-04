class CreateTokens < ActiveRecord::Migration[7.1]
  def change
    create_table :tokens, id: :uuid do |t|
      t.string :value
      t.jsonb :annotations
      t.string :original_value
      t.string :context

      t.timestamps
    end
  end
end
