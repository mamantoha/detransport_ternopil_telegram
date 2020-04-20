require "jennifer"
require "jennifer/adapter/postgres"

Jennifer::Config.read("config/database.yml", :development)

Jennifer::Config.configure do |conf|
  log_file = File.new("#{__DIR__}/../../log/jennifer.log", "a")
  stdout = STDOUT

  writer = IO::MultiWriter.new(log_file, stdout)

  conf.logger = ::Log.for("db", :debug)
  conf.logger.backend = ::Log::IOBackend.new(writer)
end
