require "clear"
require "../../src/models/*"

Clear::SQL.init(ENV["DATABASE_URL"])

log_file =
  case ENV["CRYSTAL_ENV"]
  when "production"
    File.new("#{__DIR__}/../../log/clear.log", "a+")
  else
    STDOUT
  end

Log.builder.bind "clear.*", :debug, Log::IOBackend.new(log_file)
