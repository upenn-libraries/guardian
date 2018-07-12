class GlacierArchives < ActiveRecord::Migration[4.2]
  def self.up
    create_table :glacier_archives do |t|
      t.string :archive_id
      t.string :description
    end
  end
end