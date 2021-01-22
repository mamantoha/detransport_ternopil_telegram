require "clear"
require "../../src/models/*"

Clear::SQL.init(ENV["DATABASE_URL"])

log_file = File.new("#{__DIR__}/../../log/clear.log", "a+")
stdout = STDOUT

writer = IO::MultiWriter.new(log_file, stdout)

Log.builder.bind "clear.*", :debug, Log::IOBackend.new(writer)
