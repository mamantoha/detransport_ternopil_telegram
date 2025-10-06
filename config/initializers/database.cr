require "lustra"
require "../../src/models/*"

Lustra::SQL.init(ENV["DATABASE_URL"])

log_file = File.new("#{__DIR__}/../../log/lustra.log", "a+")
stdout = STDOUT

writer = IO::MultiWriter.new(log_file, stdout)

Log.builder.bind "lustra.*", :debug, Log::IOBackend.new(writer)
