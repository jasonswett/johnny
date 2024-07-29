class RemoveIndexFromSentences < ActiveRecord::Migration[7.1]
  def change
    remove_index :sentences, :value
  end
end
