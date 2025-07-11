module DetransportTelegram
  class CallbackQueryHandler
    getter callback_query : TelegramBot::CallbackQuery
    getter bot : DetransportTelegram::Bot
    getter chat_id : Int64?

    def initialize(@callback_query, @bot)
      if message = callback_query.message
        @chat_id = message.chat.id
      end
    end

    def handle
      if chat_id = @chat_id
        callback_data = @callback_query.data

        return unless callback_data

        case callback_data
        when /^update_(\d+)$/
          stop_id = $1.to_i
          handle_update_routes(chat_id, stop_id)
        when /^map_(\d+)$/
          stop_id = $1.to_i
          handle_stop_location(chat_id, stop_id)
        when /^info_(\d+)$/
          stop_id = $1.to_i
          handle_stop_info(chat_id, stop_id)
        when "delete_message"
          handle_delete_message(chat_id)
        else
          stop_id = callback_data.to_i
          handle_stop_selection(chat_id, stop_id)
        end
      end
    end

    private def handle_stop_selection(chat_id : Int64, stop_id : Int32)
      bot.send_message(
        chat_id: chat_id,
        text: routes_text(stop_id),
        parse_mode: "Markdown",
        reply_markup: update_keyboard(stop_id)
      )
    end

    private def handle_update_routes(chat_id : Int64, stop_id : Int32)
      # Find the message to update
      if message = @callback_query.message
        bot.edit_message_text(
          chat_id: chat_id,
          message_id: message.message_id,
          text: routes_text(stop_id),
          parse_mode: "Markdown",
          reply_markup: update_keyboard(stop_id)
        )
      end
    end

    private def handle_stop_location(chat_id : Int64, stop_id : Int32)
      if stop = stops.get_by_id(stop_id.to_s)
        coord = Geo::Coord.new(stop.lat.to_f, stop.lng.to_f)

        buttons = [
          [
            TelegramBot::InlineKeyboardButton.new(
              text: "🗑 #{I18n.translate("messages.delete_message")}",
              callback_data: "delete_message"
            ),
          ],
        ]

        keyboard = TelegramBot::InlineKeyboardMarkup.new(buttons)

        bot.send_venue(
          chat_id,
          latitude: stop.lat.to_f,
          longitude: stop.lng.to_f,
          title: stop.full_name,
          address: "\n🧭 #{coord}",
          reply_markup: keyboard
        )
      end
    end

    private def handle_stop_info(chat_id : Int64, stop_id : Int32)
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
        io << "🚫 #{I18n.translate("messages.no_infomation")}"
      end

      buttons = [
        [
          TelegramBot::InlineKeyboardButton.new(
            text: "🗑 #{I18n.translate("messages.delete_message")}",
            callback_data: "delete_message"
          ),
        ],
      ]

      keyboard = TelegramBot::InlineKeyboardMarkup.new(buttons)

      bot.send_message(chat_id, io.to_s, reply_markup: keyboard)
    end

    private def update_keyboard(stop_id : Int32)
      buttons = [] of Array(TelegramBot::InlineKeyboardButton)

      buttons << [
        TelegramBot::InlineKeyboardButton.new(
          text: "🔄 #{I18n.translate("messages.update_routes")}",
          callback_data: "update_#{stop_id}"
        ),
      ]

      buttons << [
        TelegramBot::InlineKeyboardButton.new(
          text: "🗺#{I18n.translate("messages.show_stop_on_map")}",
          callback_data: "map_#{stop_id}"
        ),
        TelegramBot::InlineKeyboardButton.new(
          text: "ℹ️ #{I18n.translate("messages.show_stop_info")}",
          callback_data: "info_#{stop_id}"
        ),
      ]

      buttons << [
        TelegramBot::InlineKeyboardButton.new(
          text: "🗑 #{I18n.translate("messages.delete_message")}",
          callback_data: "delete_message"
        ),
      ]

      TelegramBot::InlineKeyboardMarkup.new(buttons)
    end

    private def handle_delete_message(chat_id : Int64)
      if message = @callback_query.message
        bot.delete_message(chat_id, message.message_id)
      end
    end

    private def routes_text(stop_id)
      detransport_api = DetransportTelegram::DetransportAPI.new

      detransport_vehicles = detransport_api.show_stop(stop_id)

      routes = detransport_vehicles.vehicles.sort_by(&.time).reduce([] of String) do |arry, route|
        arry << route.full_name
      end

      stop_name = detransport_api.stops.stops.find { |s| s.id == stop_id.to_s }.try(&.name)

      current_time = Time.local(Time::Location.load("Europe/Kyiv"))
      formatted_time = current_time.to_s("%Y-%m-%d %H:%M:%S")

      String::Builder.build do |io|
        io << "🚏 `#{stop_name}`" << "\n"
        io << "_#{I18n.translate("messages.last_updated")}: #{formatted_time}_" << "\n"
        io << "\n"
        if routes.empty?
          io << "🚫 #{I18n.translate("messages.no_infomation")}" << "\n"
        else
          routes.each { |el| io << el << "\n" }
        end
      end
    end

    private def stops
      detransport_api = DetransportTelegram::DetransportAPI.new

      detransport_api.stops
    end
  end
end
