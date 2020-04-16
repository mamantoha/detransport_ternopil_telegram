require "log"
require "json"
require "telegram_bot"
require "dotenv"
require "geo"
require "haversine"
require "crest"
require "jaro_winkler"
require "i18n"
require "humanize_time"
require "./detransport_telegram/*"

require "../config/initializers/database"
require "./models/*"

I18n::Backend::Yaml.embed(["#{__DIR__}/locales"])

I18n.init

I18n.default_locale = "uk"

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
    bot.polling
  end
end

DetransportTelegram.run
