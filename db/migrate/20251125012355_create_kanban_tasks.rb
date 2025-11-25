class CreateKanbanTasks < ActiveRecord::Migration[7.0]
  def change
    create_table :kanban_tasks do |t|
      t.string :name, null: false
      t.string :status, null: false, default: 'to_do'
      t.references :created_by, null: false, foreign_key: { to_table: :users }
      t.string :task_type, null: false
      t.date :deadline
      t.text :description
      t.integer :position, default: 0

      t.timestamps
    end

    add_index :kanban_tasks, :status
    add_index :kanban_tasks, :task_type
    add_index :kanban_tasks, :deadline
  end
end
