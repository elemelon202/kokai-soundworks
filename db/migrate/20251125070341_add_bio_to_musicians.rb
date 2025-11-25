class AddBioToMusicians < ActiveRecord::Migration[7.1]
  def change
    add_column :musicians, :bio, :text
  end
end
