class CreatePartOfSpeechTags < ActiveRecord::Migration[7.1]
  def change
    create_table :part_of_speech_tags, id: :uuid do |t|
      t.references :token, null: false, foreign_key: true, type: :uuid
      t.string :part_of_speech

      t.timestamps
    end

    add_index :part_of_speech_tags, [:token_id, :part_of_speech], unique: true
  end
end
