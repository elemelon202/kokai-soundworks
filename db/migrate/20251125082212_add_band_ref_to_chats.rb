class AddBandRefToChats < ActiveRecord::Migration[7.0]
  def change
    # Add band_id as nullable first
    add_reference :chats, :band, foreign_key: true
  end
end
