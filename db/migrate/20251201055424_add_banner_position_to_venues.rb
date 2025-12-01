class AddBannerPositionToVenues < ActiveRecord::Migration[7.1]
  def change
    add_column :venues, :banner_position, :integer
  end
end
