require "lustra/cli"

require "../config/config"
require "./db/migrations/*"

Lustra::CLI.run
