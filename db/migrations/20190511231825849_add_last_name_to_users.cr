class AddLastNameToUsers < Jennifer::Migration::Base
  def up
    change_table(:users) do |t|
      t.add_column(:last_name, :string)
    end
  end

  def down
    change_table(:users) do |t|
      t.drop_column(:last_name)
    end
  end
end
