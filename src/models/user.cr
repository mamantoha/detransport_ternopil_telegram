class User
  include Clear::Model

  primary_key

  column telegram_id : Int32
  column first_name : String
  column last_name : String?
  column username : String?
  column language_code : String?

  timestamps
end
