class TodoFiles < ActiveRecord::Migration[4.2]
  def change
    def self.up
      create_table :todo_files do |t|
        t.timestamps
        t.string :vault
        t.string :name
        t.string :source
        t.string :status
        t.string :source_timestamp
      end
    end
  end
end
