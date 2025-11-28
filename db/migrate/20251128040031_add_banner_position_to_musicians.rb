class AddBannerPositionToMusicians < ActiveRecord::Migration[7.1]
  def change
    add_column :musicians, :banner_position, :integer
  end
end
