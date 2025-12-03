class AddBandAndAssigneeToKanbanTasks < ActiveRecord::Migration[7.1]
  def change
    add_reference :kanban_tasks, :band, foreign_key: true
    add_reference :kanban_tasks, :assigned_to, foreign_key: { to_table: :musicians }
  end
end
