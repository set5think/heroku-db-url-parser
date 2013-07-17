require 'heroku/command/db'

class Heroku::Command::Db

  # db:parse_db_url [DATABASE_URL] [--format {psql|pgpass|rails_yaml|pg_dump|pg_restore|alias} [-aliasname NAME]
  #
  # generates a string to the format specified, psql by default, DATABASE_URL by default
  #
  # -f, --format FORMAT   # set the output format (psql, pgpass, all)
  #                       # accepts comma seperated list
  # --aliasname NAME      # name of alias used for the alias format option
  #
  #Examples:
  #
  # $ heroku db:parse_db_url HEROKU_POSTGRESQL_NAVY --format=pgpass
  #
  # $ heroku db:parse_db_url HEROKU_POSTGRESQL_NAVY # generates psql string if no --format provided
  #
  # $ heroku db:parse_db_url # generates psql string for DATABASE_URL
  #
  # $ heroku db:parse_db_url --format alias --aliasname pgtest  # generates an alias declaration for a bash_profile
  #

  def parse_db_url
    db = args.detect { |a| a.include?('HEROKU_POSTGRESQL_') } || 'DATABASE_URL'

    format = options[:format] || 'psql'
    formats = format.split(/\s*,\s*/)
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

    formats.each do |f|
      display case f
      when "psql", nil
        psqlify(uri_parts)
      when "pgpass"
        pgpassify(uri_parts)
      when "rails_yaml"
        rails_yamlify(uri_parts)
      when "pg_dump"
        pgdumpify(uri_parts)
      when "pg_restore"
        pgrestorify(uri_parts)
      when "alias"
        aname = options[:aliasname] || 'aliasname'
        "alias #{aname}='#{psqlify(uri_parts)}'"
      else
        "#{f} not known or supported. Please use one of |psql,pgpass,rails_yaml,pg_dump,pg_restore,alias|'"
      end
    end
  end

  protected

  def psqlify(uri_hash)
    "psql -h #{uri_hash[:host]} -d #{uri_hash[:db]} -U #{uri_hash[:user]} -p #{uri_hash[:port]}"
  end

  def pgpassify(uri_hash)
    "#{uri_hash[:host]}:#{uri_hash[:port]}:#{uri_hash[:db]}:#{uri_hash[:user]}:#{uri_hash[:pw]}"
  end

  def rails_yamlify(uri_hash)
    "host: #{uri_hash[:host]}\ndatabase: #{uri_hash[:db]}\nusername: #{uri_hash[:user]}\npassword: #{uri_hash[:pw]}\nport: #{uri_hash[:port]}"
  end

  def pgdumpify(uri_hash)
    "pg_dump #{uri_hash[:db]} -h #{uri_hash[:host]} -p #{uri_hash[:port]} -U #{uri_hash[:user]}"
  end

  def pgrestorify(uri_hash)
    "pg_restore -d #{uri_hash[:db]} -h #{uri_hash[:host]} -p #{uri_hash[:port]} -U #{uri_hash[:user]}"
  end

  def cleanse_path(path)
    path.sub(/^\//,'')
  end

end
