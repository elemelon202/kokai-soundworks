class AddProcessedAtToLineMessages < ActiveRecord::Migration[7.1]
  def change
    add_column :line_messages, :processed_at, :datetime
  end
end
