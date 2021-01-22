require "log"
require "json"
require "telegram_bot"
require "geo"
require "haversine"
require "crest"
require "jaro_winkler"
require "i18n"
require "humanize_time"
require "./detransport_telegram/*"

require "../config/config"

I18n.config.loaders << I18n::Loader::YAML.new("#{__DIR__}/locales")
I18n.config.default_locale = :uk
I18n.init

module DetransportTelegram
  VERSION = "0.1.0"

  Log = ::Log.for(self)
  Log.level = :debug

  log_file = File.new("#{__DIR__}/../log/telegram.log", "a")
  stdout = STDOUT

  writer = IO::MultiWriter.new(log_file, stdout)

  Log.backend = ::Log::IOBackend.new(writer)

  def self.run
    Dotenv.load

    bot = DetransportTelegram::Bot.new

    Log.info { "DetransportTelegram started." }

    commands = [
      TelegramBot::BotCommand.new(command: "help", description: "інформація про бота"),
      TelegramBot::BotCommand.new(command: "ping", description: "pong 🏓"),
    ]

    bot.set_my_commands(commands)

    bot.polling
  end
end

DetransportTelegram.run
