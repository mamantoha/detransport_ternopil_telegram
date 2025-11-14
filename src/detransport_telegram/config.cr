module DetransportTelegram
  module Config
    extend self

    def telegram_token : String
      ENV["BOT_TOKEN"]
    end

    def telegram_bot_name : String
      ENV["BOT_NAME"]
    end

    def admin_telegram_id : Int64
      ENV["ADMIN_TELEGRAM_ID"].to_i64
    end

    def date
      {{ `date -R`.stringify.chomp }}
    end
  end
end
