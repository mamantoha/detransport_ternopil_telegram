class CreateUser
  include Clear::Migration

  def change(direction)
    direction.up do
      create_table(:users) do |t|
        t.column :telegram_id, :integer, null: false
        t.column :first_name, :string
        t.column :last_name, :string
        t.column :username, :string
        t.column :language_code, :string

        t.timestamps
      end
    end

    direction.down do
      execute("DROP TABLE users")
    end
  end
end
