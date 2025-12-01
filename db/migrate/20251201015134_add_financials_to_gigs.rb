class AddFinancialsToGigs < ActiveRecord::Migration[7.1]
  def change
    add_column :gigs, :ticket_price, :decimal
  end
end
