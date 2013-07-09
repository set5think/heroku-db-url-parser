require 'heroku/command/db'

class Heroku::Command::Db

  # db:parse_db_url [DATABASE_URL] [--format {psql|pgpass|all}] [--alias NAME] [--append] [--bashfile BASHRC_PATH] [--pgpass PGPASS_PATH]
  #
  # generates a string to the format specified, psql by default, DATABASE_URL by default
  #
  # -f, --format FORMAT   # set the output format (psql, pgpass, all)
  # --append              # append output to bash_profile (as an alias) and pgpass
  # --alias NAME          # name of alias for bash_profile.
  # --bashfile            # path to bashrc or bash_profile for appending. Defaults to ~/.bash_profile
  # --pgpass              # path to pgpass file for appending. Defaults to ~/.pgpass
  #
  #Examples:
  #
  # $ heroku db:parse_db_url HEROKU_POSTGRESQL_NAVY --format=pgpass
  #
  # $ heroku db:parse_db_url HEROKU_POSTGRESQL_NAVY # generates psql string if no --format provided
  #
  # $ heroku db:parse_db_url # generates psql string for DATABASE_URL
  #
  # $ heroku db:parse_db_url --format all --append --alias db1 --bashfile /home/zaphod/.aliased
  #

  def parse_db_url
    db = args.detect { |a| a.include?('HEROKU_POSTGRESQL_') } || 'DATABASE_URL'

    format = options[:format] || 'psql'
    append = options[:append] || false

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

    case format
      when 'psql', 'all'
        display(psqlify(uri_parts))
      when 'pgpass', 'all'
        display(pgpassify(uri_parts))
      else
        display("#{format} not known or supported. Please use 'psql' or 'pgpass'")
    end

    if append
      bash   = options[:bashfile] || "#{ENV['HOME']}/.bash_profile"
      pgpass = options[:pgpass]   || "#{ENV['HOME']}/.pgpass"

      if options[:alias] && !File.exists?(bash) 
          display "File does not exists: #{bash}"
      elsif !File.exists?(pgpass)
          display "File does not exists: #{pgpass}"
      else
        if options[:alias]
          alias_text = "alias #{options[:alias]}='#{psqlify(uri_parts)}'"
          append_to_file(bash, alias_text)
        end
        append_to_file(pgpass, pgpassify(uri_parts))
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

  def cleanse_path(path)
    path.sub(/^\//,'')
  end

  def append_to_file(file, text)
    raise "unable to write to #{file}" unless File.writable?(file)
    display "Appending #{text} to #{file}"
    open(file, 'a') do |f|
      f.puts text
    end
  end

end
