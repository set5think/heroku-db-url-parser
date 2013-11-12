require 'heroku/command/pg'

class Heroku::Command::Pg

  # pg:parse_db_url [DATABASE_URL] [--format {psql|pgpass|rails_yaml|pg_dump|pg_restore|alias|sqitch} [-aliasname NAME]
  #
  # generates a string to the format specified, psql by default, DATABASE_URL by default
  #
  # -f, --format FORMAT     # set the output format (psql, pgpass, all)
  #                         # accepts comma seperated list
  # --aliasname NAME        # name of alias used for the alias format option
  # --aliascommand COMMAND  # command to alias, psql by default
  #
  #Examples:
  #
  # $ heroku pg:parse_db_url HEROKU_POSTGRESQL_NAVY --format=pgpass
  #
  # $ heroku pg:parse_db_url HEROKU_POSTGRESQL_NAVY # generates psql string if no --format provided
  #
  # $ heroku pg:parse_db_url # generates psql string for DATABASE_URL
  #
  # $ heroku pg:parse_db_url --format alias --aliasname pgtest  # generates an alias declaration for a bash_profile
  #
  # $ heroku pg:parse_db_url --format alias --aliasname pgtest --aliascommand pg_dump # generates a pg_dump alias declaration for a bash_profile
  #

  def parse_db_url
    db = args.detect { |a| a.include?('HEROKU_POSTGRESQL_') } || 'DATABASE_URL'

    format = options[:format] || 'psql'
    formats = format.split(/\s*,\s*/)
    @db_info = {}

    heroku.config_vars(app).select do |k, v|
      if k.include?(db)
        @db_info[:name] = k
        @db_info[:conn_string] = v
      end
    end

    parse_conn_string

    return "#{uri_parts[:scheme]} not supported yet" if uri_parts[:scheme] != 'postgres'

    formats.each do |f|
      display render_format(f)
    end
  end

  protected

  def parse_conn_string(conn_string=@db_info[:conn_string])
    @uri = URI.parse(conn_string)
  end

  def uri_parts
    @parts ||= {
     :host    => @uri.host,
     :db      => cleanse_path(@uri.path),
     :user    => @uri.user,
     :pw      => @uri.password,
     :scheme  => @uri.scheme,
     :port    => @uri.port
    }
  end

  def render_format(_format)
    case _format
    when "psql", nil
      psqlify(uri_parts)
    when "pgpass"
      pgpassify(uri_parts)
    when "rails_yaml"
      rails_yamlify(uri_parts)
    when "pg_dump"
      pg_dumpify(uri_parts)
    when "pg_restore"
      pg_restorify(uri_parts)
    when "sqitch"
      sqitchify(uri_parts)
    when "alias"
      aname = options[:aliasname] || 'aliasname'
      acommand = options[:aliascommand] || 'psql'
      acommand = 'psql' if acommand == 'alias'
      "alias #{aname}='#{render_format(acommand)}'"
    else
      "#{_format} not known or supported. Please use one of |psql,pgpass,rails_yaml,pg_dump,pg_restore,alias,sqitch|'"
    end
  end

  def psqlify(uri_hash=uri_parts)
    "psql -h #{uri_hash[:host]} -d #{uri_hash[:db]} -U #{uri_hash[:user]} -p #{uri_hash[:port]}"
  end

  def pgpassify(uri_hash=uri_parts)
    "#{uri_hash[:host]}:#{uri_hash[:port]}:#{uri_hash[:db]}:#{uri_hash[:user]}:#{uri_hash[:pw]}"
  end

  def rails_yamlify(uri_hash=uri_parts)
    "host: #{uri_hash[:host]}\ndatabase: #{uri_hash[:db]}\nusername: #{uri_hash[:user]}\npassword: #{uri_hash[:pw]}\nport: #{uri_hash[:port]}"
  end

  def pg_dumpify(uri_hash=uri_parts)
    "pg_dump #{uri_hash[:db]} -h #{uri_hash[:host]} -p #{uri_hash[:port]} -U #{uri_hash[:user]}"
  end

  def pg_restorify(uri_hash=uri_parts)
    "pg_restore -d #{uri_hash[:db]} -h #{uri_hash[:host]} -p #{uri_hash[:port]} -U #{uri_hash[:user]}"
  end

  def sqitchify(uri_hash=uri_parts)
    "sqitch -d #{uri_hash[:db]} -h #{uri_hash[:host]} -p #{uri_hash[:port]} -u #{uri_hash[:user]}"
  end

  def cleanse_path(path)
    path.sub(/^\//,'')
  end

end
