class GlacierArchives < ActiveRecord::Migration[4.2]
  def self.up
    create_table :glacier_archives do |t|
      t.timestamps
      t.string :vault
      t.string :archive_id
      t.text :description
    end
  end
end