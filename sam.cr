require "dotenv"
Dotenv.load

require "sam"
require "./config/initializers/database"
require "./db/migrations/*"

load_dependencies "jennifer"

Sam.help
