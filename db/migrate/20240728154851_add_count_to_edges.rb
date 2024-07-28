class AddCountToEdges < ActiveRecord::Migration[7.1]
  def change
    add_column :edges, :count, :integer, null: false, default: 0
  end
end
