if Heroku::VERSION.to_f >= 3.0
  require 'db/heroku/command/pg'
else
  require 'db/heroku/command/db'
end
