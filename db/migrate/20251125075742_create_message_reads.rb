class CreateMessageReads < ActiveRecord::Migration[7.1]
  def change
    create_table :message_reads do |t|
      t.references :message, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.boolean :read , default: false

      t.timestamps
    end
  end
end
