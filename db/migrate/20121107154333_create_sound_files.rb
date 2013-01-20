class CreateSoundFiles < ActiveRecord::Migration
  def change
    create_table :sound_files do |t|
      t.string      :name
      t.text        :description
      t.attachment  :file
      t.attachment  :wave
      t.attachment  :preview
      t.attachment  :thumbnail
      t.integer     :length, :default => 0
      t.integer     :bpm,:default => 0
      t.integer     :listen_count,:default => 0
      t.integer     :sound_file_bookmarks_count,:default => 0
      t.string      :type
      t.string      :created_by

      t.timestamps
    end
  end
end
