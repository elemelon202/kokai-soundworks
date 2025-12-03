class AddEndDateToMemberAvailabilities < ActiveRecord::Migration[7.1]
  def change
    rename_column :member_availabilities, :available_date, :start_date
    add_column :member_availabilities, :end_date, :date
  end
end
