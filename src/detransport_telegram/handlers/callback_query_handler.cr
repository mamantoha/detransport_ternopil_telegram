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
        bot.answer_callback_query(@callback_query.id, cache_time: 1)

        stop_id = @callback_query.data

        keyboard = TelegramBot::ReplyKeyboardRemove.new
        bot.send_message(chat_id, routes_text(stop_id), parse_mode: "Markdown", reply_markup: keyboard)
      end
    end

    private def routes_text(stop_id)
      detransport_api = DetransportTelegram::DetransportAPI.new

      detransport_vehicles = detransport_api.show_stop(stop_id)

      routes = detransport_vehicles.vehicles.sort_by(&.time).reduce([] of String) do |arry, route|
        arry << route.full_name
      end

      stop_name = detransport_api.stops.stops.find { |s| s.id == stop_id }.try(&.name)

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
