class AddLocationToBands < ActiveRecord::Migration[7.1]
  def change
    add_column :bands, :location, :string
  end
end
