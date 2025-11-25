class AddFieldsToKanbanTasks < ActiveRecord::Migration[7.1]
  def change
    add_column :kanban_tasks, :name, :string
    add_column :kanban_tasks, :status, :string
    add_column :kanban_tasks, :task_type, :string
    add_column :kanban_tasks, :deadline, :date
    add_column :kanban_tasks, :description, :text
    add_column :kanban_tasks, :position, :integer
    add_column :kanban_tasks, :created_by_id, :integer
  end
end
