class ChangeLineGroupIdNullableInLineBandConnections < ActiveRecord::Migration[7.1]
  def change
    change_column_null :line_band_connections, :line_group_id, true
  end
end
