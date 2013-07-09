require 'heroku/command/db'

class Heroku::Command::Db

  # db:parse_db_url [DATABASE_URL] [--format={psql|pgpass}]
  #
  # generates a string to the format specified, psql by default, DATABASE_URL by default
  #
  #Examples:
  #
  # $ heroku db:parse_db_url HEROKU_POSTGRESQL_NAVY --format=pgpass
  #
  # $ heroku db:parse_db_url HEROKU_POSTGRESQL_NAVY # generates psql string if no --format provided
  #
  # $ heroku db:parse_db_url # generates psql string for DATABASE_URL
  #

  def parse_db_url

    db = args.detect { |a| a.include?('HEROKU_POSTGRESQL_') } || 'DATABASE_URL'

    format = args.detect { |a| a.include?("--format") }

    format = format.split(/=/)[1] rescue nil

    db_info = {}

    heroku.config_vars(app).select do |k, v|
      if k.include?(db)
        db_info[:name] = k
        db_info[:conn_string] = v
      end
    end

    uri = URI.parse(db_info[:conn_string])
    uri_parts = {
      :host   => uri.host,
      :db     => cleanse_path(uri.path),
      :user   => uri.user,
      :pw     => uri.password,
      :scheme => uri.scheme,
      :port   => uri.port
    }

    return "#{uri_parts[:scheme]} not supported yet" if uri_parts[:scheme] != 'postgres'

    if format.nil? || format == "psql"

      display(psqlify(uri_parts))

    elsif format == 'pgpass'

      display(pgpassify(uri_parts))

    else

      display("#{format} not known or supported. Please use 'psql' or 'pgpass'")

    end

  end

  protected

  def psqlify(uri_hash)
    "psql -h #{uri_hash[:host]} -d #{uri_hash[:db]} -U #{uri_hash[:user]} -p #{uri_hash[:port]}"
  end

  def pgpassify(uri_hash)
    "#{uri_hash[:host]}:#{uri_hash[:port]}:#{uri_hash[:db]}:#{uri_hash[:user]}:#{uri_hash[:pw]}"
  end

  def cleanse_path(path)
    path.sub(/^\//,'')
  end

end
