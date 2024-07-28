class AddUniqueIndexToTokens < ActiveRecord::Migration[7.1]
  def change
    add_index :tokens, :value, unique: true
  end
end
