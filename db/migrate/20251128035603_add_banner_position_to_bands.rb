class AddBannerPositionToBands < ActiveRecord::Migration[7.1]
  def change
    add_column :bands, :banner_position, :integer, default: 50
  end
end
