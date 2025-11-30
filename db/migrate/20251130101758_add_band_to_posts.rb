class AddBandToPosts < ActiveRecord::Migration[7.1]
  def change
    add_reference :posts, :band, null: true, foreign_key: true
  end
end
