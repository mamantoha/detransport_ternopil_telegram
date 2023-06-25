class ChangeUsersTelegramId
  include Clear::Migration

  def change(dir)
    dir.up do
      change_column_type("users", "telegram_id", "integer", "bigint")
    end

    dir.down do
      change_column_type("users", "telegram_id", "integer", "bigint")
    end
  end
end
