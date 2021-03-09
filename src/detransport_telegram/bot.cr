require "./handlers/*"

module DetransportTelegram
  class Bot < TelegramBot::Bot
    include TelegramBot::CmdHandler

    def initialize
      super(Config.telegram_bot_name, Config.telegram_token)
    end

    def handle(message : TelegramBot::Message)
      handle_with(message, DetransportTelegram::MessageHandler)
    end

    def handle(callback_query : TelegramBot::CallbackQuery)
      handle_with(callback_query, DetransportTelegram::CallbackQueryHandler)
    end

    private def handle_with(obj, klass)
      time = Time.utc
      DetransportTelegram::Log.info { "> #{obj.class.name} #{obj.to_json}" }

      if user = load_user(obj)
        user.touch
      end

      klass.new(obj, self).handle

      DetransportTelegram::Log.debug { "Handled #{obj.class.name} in #{Time.utc - time}" }
      true
    rescue e
      DetransportTelegram::Log.error { e.inspect_with_backtrace }
      false
    end

    private def load_user(msg) : User?
      if telegram_user = msg.from
        User.query.find_or_create(telegram_id: telegram_user.id) do |user|
          user.telegram_id = telegram_user.id
          user.first_name = telegram_user.first_name
          user.last_name = telegram_user.last_name
          user.username = telegram_user.username
          user.language_code = telegram_user.language_code
        end
      end
    end
  end
end
