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
        handle_covid19_message
        handle_location(message_location)
      else
        nil
      end
    end

    private def handle_text(message, text : String)
      if text.starts_with?("/")
        handle_commands(message, text)
      else
        handle_covid19_message
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
      when r = /^\/map(\d+)/
        if m = text.match(r)
          stop_id = m[1].to_i
          handle_stop_location(stop_id)
        end
      when r = /^\/info(\d+)/
        if m = text.match(r)
          stop_id = m[1].to_i
          handle_stop_info(stop_id)
        end
      else
        nil
      end
    end

    private def handle_covid19_message
      text = <<-TEXT
      На період карантину в Тернополі призупининено роботу громадського транспорту.

      Натомість курсуватимуть спецрейси.

      Спецрейси перевозитимуть виключно працівників медичних установ, аварійних та комунальних служб, правоохоронців та інших служб, які повинні забезпечувати життя міста в умовах карантину.

      Під час карантину залишайтеся вдома! Подбайте про самоізоляцію. Проводьте час із родиною, дотримуйтеся правил особистої гігієни та будьте здорові!

      Дізнавайтеся інформацію щодо коронавірусу з офіційних джерел.

      https://t.me/covid19_ternopil
      TEXT

      bot.send_message(chat_id, text)
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
      Build with:

      Crystal #{Crystal::VERSION}
      HEREDOC

      bot.send_message(chat_id, text, parse_mode: "Markdown")
    end

    private def handle_help
      text = I18n.translate("messages.help")

      buttons = [
        [
          TelegramBot::KeyboardButton.new(I18n.translate("messages.share_location"), request_contact: false, request_location: true),
        ],
      ]

      keyboard = TelegramBot::ReplyKeyboardMarkup.new(buttons, resize_keyboard: true)

      bot.send_message(chat_id, text, reply_markup: keyboard, parse_mode: "Markdown")
    end

    private def build_keyboard_for_nearest_stops(stops : Array(DetransportTelegram::DetransportAPI::Stop), location : TelegramBot::Location)
      stops.reduce([] of Array(TelegramBot::InlineKeyboardButton)) do |arry, stop|
        distance = Haversine.distance(stop.lat.to_f, stop.lng.to_f, location.latitude, location.longitude)
        text = "#{stop.full_name} - #{I18n.translate("messages.meters", count: distance.to_meters.to_i)}"
        arry << [TelegramBot::InlineKeyboardButton.new(text: text, callback_data: "#{stop.id}")]
      end
    end

    private def build_keyboard_for_simital_stops(stops : Array(DetransportTelegram::DetransportAPI::Stop))
      stops.reduce([] of Array(TelegramBot::InlineKeyboardButton)) do |arry, stop|
        text = "#{stop.full_name}"
        arry << [TelegramBot::InlineKeyboardButton.new(text: text, callback_data: "#{stop.id}")]
      end
    end

    private def stops
      detransport_api = DetransportTelegram::DetransportAPI.new

      detransport_api.stops
    end

    private def handle_stop_location(stop_id : Int32)
      if stop = stops.get_by_id(stop_id.to_s)
        coord = Geo::Coord.new(stop.lat.to_f, stop.lng.to_f)

        bot.send_venue(
          chat_id,
          latitude: stop.lat.to_f,
          longitude: stop.lng.to_f,
          title: stop.full_name,
          address: "\n🧭 #{coord}"
        )
      end
    end

    private def handle_stop_info(stop_id : Int32)
      io = String::Builder.new

      if stop = stops.get_by_id(stop_id.to_s)
        io << stop.full_name
        io << "\n\n"
        io << I18n.translate("messages.vehicles_list")
        io << ":"
        io << "\n\n"
        stop.vehicles.each do |vehicle|
          io << "#{vehicle.icon} #{vehicle.name}"
          io << "\n"
        end
      else
        io << I18n.translate("messages.no_infomation")
      end

      bot.send_message(chat_id, io.to_s)
    end

    private def swap_keyboard_layout_from_latin_to_ua(text : String)
      chars_hash = {'q' => 'й', 'w' => 'ц', 'e' => 'у', 'r' => 'к', 't' => 'е', 'y' => 'н', 'u' => 'г', 'i' => 'ш', 'o' => 'щ', 'p' => 'з', '[' => 'х', ']' => 'ї', '\\' => 'ґ', 'a' => 'ф', 's' => 'і', 'd' => 'в', 'f' => 'а', 'g' => 'п', 'h' => 'р', 'j' => 'о', 'k' => 'л', 'l' => 'д', ';' => 'ж', '\'' => 'є', 'z' => 'я', 'x' => 'ч', 'c' => 'с', 'v' => 'м', 'b' => 'и', 'n' => 'т', 'm' => 'ь', ',' => 'б', '.' => 'ю', '/' => '.', 'Q' => 'Й', 'W' => 'Ц', 'E' => 'У', 'R' => 'К', 'T' => 'Е', 'Y' => 'Н', 'U' => 'Г', 'I' => 'Ш', 'O' => 'Щ', 'P' => 'З', '{' => 'Х', '}' => 'Ї', '|' => 'Ґ', 'A' => 'Ф', 'S' => 'І', 'D' => 'В', 'F' => 'А', 'G' => 'П', 'H' => 'Р', 'J' => 'О', 'K' => 'Л', 'L' => 'Д', ':' => 'Ж', '"' => 'Є', 'Z' => 'Я', 'X' => 'Ч', 'C' => 'С', 'V' => 'М', 'B' => 'И', 'N' => 'Т', 'M' => 'Ь', '<' => 'Б', '>' => 'Ю', '?' => ','}
      text.gsub(chars_hash)
    end
  end
end
