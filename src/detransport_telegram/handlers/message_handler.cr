module DetransportTelegram
  class MessageHandler
    getter message : TelegramBot::Message
    getter bot : DetransportTelegram::Bot
    getter chat_id : Int64

    def initialize(@message, @bot)
      @chat_id = @message.chat.id
    end

    def handle
      if message_text = message.text
        handle_text(message, message_text)
      elsif message_location = message.location
        handle_location(message_location)
      else
        nil
      end

      bot.delete_message(chat_id, message.message_id)
    end

    private def handle_text(message, text : String)
      if text.starts_with?("/")
        handle_commands(message, text)
      else
        handle_similar_stops(text)
      end
    end

    private def handle_commands(message, text : String)
      case text
      when /^\/(help|start)/
        handle_help
      when /^\/about/
        handle_about
      when /^\/ping/
        bot.reply(message, "🏓")
      when /^\/admin:(\w+)/
        return unless authorize_admin!(message)

        case $1
        when "users"
          handle_users(message)
        end
      else
        nil
      end
    end

    private def handle_similar_stops(stop : String)
      text = I18n.translate("messages.select_stop")
      stop = swap_keyboard_layout_from_latin_to_ua(stop)

      simital_stops = stops.similar_to(stop)

      buttons = build_keyboard_for_simital_stops(simital_stops)

      keyboard = TelegramBot::InlineKeyboardMarkup.new(buttons)

      bot.send_message(chat_id, text, reply_markup: keyboard)
    end

    private def handle_location(location : TelegramBot::Location)
      text = I18n.translate("messages.nearest_stops")

      nearest_stops = stops.nearest_to(location.latitude, location.longitude)

      buttons = build_keyboard_for_nearest_stops(nearest_stops, location)
      keyboard = TelegramBot::InlineKeyboardMarkup.new(buttons)

      bot.send_message(chat_id, text, reply_markup: keyboard)
    end

    private def handle_about
      text = <<-HEREDOC
      Build with Crystal #{Crystal::VERSION}
      Build date: #{Time.parse_rfc2822(Config.date).to_s("%Y-%m-%d %H:%M:%S %:z")}
      HEREDOC

      bot.send_message(chat_id, text, parse_mode: "Markdown")
    end

    private def handle_help
      text = I18n.translate("messages.help")

      buttons = [
        [
          TelegramBot::KeyboardButton.new(
            "📍 #{I18n.translate("messages.share_location")}",
            request_contact: false,
            request_location: true
          ),
        ],
      ]

      keyboard = TelegramBot::ReplyKeyboardMarkup.new(buttons, resize_keyboard: true)

      bot.send_message(chat_id, text, reply_markup: keyboard, parse_mode: "Markdown")
    end

    def authorize_admin!(message : TelegramBot::Message) : Bool
      if telegram_user = message.from
        unless telegram_user.id == Config.admin_telegram_id
          bot.reply(message, "⛔ #{I18n.translate("admin.access_denied")}")
          return false
        end
        return true
      else
        return false
      end
    end

    private def handle_users(message : TelegramBot::Message)
      users = User.query.order_by(updated_at: :desc)

      text = String::Builder.build do |io|
        io << "👥 *#{I18n.translate("admin.users_list_title")}* (#{users.size} #{I18n.translate("admin.users_total")})"
        io << "\n\n"

        users.each_with_index do |user, index|
          io << "#{index + 1}. "
          io << "ID: `#{user.telegram_id}` "
          if user.first_name
            io << "#{user.first_name}"
          end
          if user.last_name
            io << " #{user.last_name}"
          end
          if user.username
            io << " (@#{user.username})"
          end
          io << "\n"
          io << "   📅 #{I18n.translate("admin.updated")}: `#{user.updated_at.try(&.to_s("%Y-%m-%d %H:%M"))} `\n"
          if user.language_code
            io << "   🌐 #{I18n.translate("admin.lang")}: `#{user.language_code}`\n"
          end
          io << "\n"
        end
      end.to_s

      buttons = [
        [
          TelegramBot::InlineKeyboardButton.new(
            text: "🗑 #{I18n.translate("messages.delete_message")}",
            callback_data: "delete_message"
          ),
        ],
      ]

      keyboard = TelegramBot::InlineKeyboardMarkup.new(buttons)

      bot.send_message(chat_id, text, parse_mode: "Markdown", reply_markup: keyboard)
    end

    private def build_keyboard_for_nearest_stops(stops : Array(DetransportTelegram::DetransportAPI::Stop), location : TelegramBot::Location)
      buttons = stops.reduce([] of Array(TelegramBot::InlineKeyboardButton)) do |arry, stop|
        distance = Haversine.distance(stop.lat.to_f, stop.lng.to_f, location.latitude, location.longitude)
        text = "#{stop.full_name} - #{I18n.translate("messages.meters", count: distance.to_meters.to_i)}"
        arry << [TelegramBot::InlineKeyboardButton.new(text: text, callback_data: "#{stop.id}")]
      end

      buttons << [
        TelegramBot::InlineKeyboardButton.new(
          text: "🗑 #{I18n.translate("messages.delete_message")}",
          callback_data: "delete_message"
        ),
      ]

      buttons
    end

    private def build_keyboard_for_simital_stops(stops : Array(DetransportTelegram::DetransportAPI::Stop))
      buttons = stops.reduce([] of Array(TelegramBot::InlineKeyboardButton)) do |arry, stop|
        text = "#{stop.full_name}"
        arry << [TelegramBot::InlineKeyboardButton.new(text: text, callback_data: "#{stop.id}")]
      end

      buttons << [
        TelegramBot::InlineKeyboardButton.new(
          text: "🗑 #{I18n.translate("messages.delete_message")}",
          callback_data: "delete_message"
        ),
      ]

      buttons
    end

    private def stops
      detransport_api = DetransportTelegram::DetransportAPI.new

      detransport_api.stops
    end

    private def swap_keyboard_layout_from_latin_to_ua(text : String)
      chars_hash = {'q' => 'й', 'w' => 'ц', 'e' => 'у', 'r' => 'к', 't' => 'е', 'y' => 'н', 'u' => 'г', 'i' => 'ш', 'o' => 'щ', 'p' => 'з', '[' => 'х', ']' => 'ї', '\\' => 'ґ', 'a' => 'ф', 's' => 'і', 'd' => 'в', 'f' => 'а', 'g' => 'п', 'h' => 'р', 'j' => 'о', 'k' => 'л', 'l' => 'д', ';' => 'ж', '\'' => 'є', 'z' => 'я', 'x' => 'ч', 'c' => 'с', 'v' => 'м', 'b' => 'и', 'n' => 'т', 'm' => 'ь', ',' => 'б', '.' => 'ю', '/' => '.', 'Q' => 'Й', 'W' => 'Ц', 'E' => 'У', 'R' => 'К', 'T' => 'Е', 'Y' => 'Н', 'U' => 'Г', 'I' => 'Ш', 'O' => 'Щ', 'P' => 'З', '{' => 'Х', '}' => 'Ї', '|' => 'Ґ', 'A' => 'Ф', 'S' => 'І', 'D' => 'В', 'F' => 'А', 'G' => 'П', 'H' => 'Р', 'J' => 'О', 'K' => 'Л', 'L' => 'Д', ':' => 'Ж', '"' => 'Є', 'Z' => 'Я', 'X' => 'Ч', 'C' => 'С', 'V' => 'М', 'B' => 'И', 'N' => 'Т', 'M' => 'Ь', '<' => 'Б', '>' => 'Ю', '?' => ','}
      text.gsub(chars_hash)
    end
  end
end
