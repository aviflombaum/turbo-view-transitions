class CreatePhotos < ActiveRecord::Migration[7.2]
  def change
    create_table :photos do |t|
      t.string :name
      t.string :url
      t.text :description

      t.timestamps
    end
  end
end
