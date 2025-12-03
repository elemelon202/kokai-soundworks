class ChangeLineUserIdNullableInLineUserConnections < ActiveRecord::Migration[7.1]
  def change
    change_column_null :line_user_connections, :line_user_id, true
  end
end
