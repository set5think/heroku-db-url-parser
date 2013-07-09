# Heroku Plugin for convenient format conversion of database urls

Extends `heroku db` command-line to parse database urls to other file formats.

This extension aids in the situation where you need to convert your database url to another format.  For example, if you want to create an alias to a psql connection in your .bash\_login, it gets annoying to copy and paste it and then move things around, or if you want to add this database url to your .pgpass file, which is a different format than psql.

The extension also provides the capability to append an alias to bash\_profile and/or the pgpass string to the pgpass file.

## Installation

    $ heroku plugins:install https://github.com/set5think/heroku-db-url-parser.git

## Usage

    $ heroku db:parse_db_url HEROKU_POSTGRESQL_NAVY_URL --format=pgpass

    $ heroku db:parse_db_url HEROKU_POSTGRESQL_NA --format=psql #matches the closest config env to 'HEROKU_POSTGRESQL_NA', which in this case would be HEROKU_POSTGRESQL_NAVY_URL

    $ heroku db:parse_db_url # parses DATABASE_URL and formats to psql, by default

    $ heroku db:parse_db_url --append --alias db1 --bashfile /home/zaphod/.aliases --pgpass /home/zaphod/.pgpass # appends an alias named db1 and the pgpass string to the specified files

    $ heroku db:parse_db_url --append # only appends to pgpass. Defaults to ~/.pgpass

## Todo

Support databases/data-stores other than Postgres.
Support other string formats other than psql and pgpass

## License

This plugin is released under the MIT license. See the file LICENSE.

## Copyright

Copyright &copy; 2013 Hassan Shahid.

[Contact]: mailto:set5think@gmail.com?subject=0Heroku%20DB%20URL%20Parser%20Plugin
