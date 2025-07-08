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

        if callback_data.starts_with?("update_")
          stop_id = callback_data.sub("update_", "").to_i
          handle_update_routes(chat_id, stop_id)
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

    private def update_keyboard(stop_id : Int32)
      buttons = [
        [
          TelegramBot::InlineKeyboardButton.new(
            text: "🔄 #{I18n.translate("messages.update_routes")}",
            callback_data: "update_#{stop_id}"
          ),
        ],
      ]
      TelegramBot::InlineKeyboardMarkup.new(buttons)
    end

    private def routes_text(stop_id)
      detransport_api = DetransportTelegram::DetransportAPI.new

      detransport_vehicles = detransport_api.show_stop(stop_id)

      routes = detransport_vehicles.vehicles.sort_by(&.time).reduce([] of String) do |arry, route|
        arry << route.full_name
      end

      p! detransport_api.stops.stops
      stop_name = detransport_api.stops.stops.find { |s| s.id == stop_id.to_s }.try(&.name)

      String::Builder.build do |io|
        io << "🚏 `#{stop_name}`" << "\n"
        io << "#{I18n.translate("messages.show_stop_on_map")}: /map#{stop_id}" << "\n"
        io << "#{I18n.translate("messages.show_stop_info")}: /info#{stop_id}" << "\n"
        io << "\n"
        if routes.empty?
          io << I18n.translate("messages.no_infomation") << "\n"
        else
          routes.each { |el| io << el << "\n" }
        end
      end
    end
  end
end
