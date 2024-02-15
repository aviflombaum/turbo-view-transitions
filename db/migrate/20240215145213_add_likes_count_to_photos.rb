class AddLikesCountToPhotos < ActiveRecord::Migration[7.2]
  def change
    add_column :photos, :likes_count, :integer, default: 0
  end
end
