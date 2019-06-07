class CreateUser < Jennifer::Migration::Base
  def up
    create_table(:users) do |t|
      t.integer :telegram_id
      t.string :first_name
      t.string :username
      t.string :language_code
      t.timestamps
    end
  end

  def down
    drop_table :users
  end
end
