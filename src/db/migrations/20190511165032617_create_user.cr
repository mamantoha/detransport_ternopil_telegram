class CreateUser
  include Lustra::Migration

  def change(dir)
    dir.up do
      create_table(:users) do |t|
        t.column :telegram_id, :integer, null: false
        t.column :first_name, :string
        t.column :last_name, :string
        t.column :username, :string
        t.column :language_code, :string

        t.timestamps
      end
    end

    dir.down do
      execute("DROP TABLE users")
    end
  end
end
