module DetransportTelegram
  module Config
    extend self

    def telegram_token : String
      ENV["BOT_TOKEN"]
    end

    def telegram_bot_name : String
      ENV["BOT_NAME"]
    end
  end
end
