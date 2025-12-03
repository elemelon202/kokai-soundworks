class AddStatusToMusicians < ActiveRecord::Migration[7.1]
  def change
    add_column :musicians, :status, :string
  end
end
