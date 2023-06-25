require "clear/cli"

require "../config/config"
require "./db/migrations/*"

Clear::CLI.run
