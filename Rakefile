require 'active_record'

require_relative 'lib/secrets_manager'

task :db_migrate do
  db = SecretsManager.load_secrets('secrets/db.yml')
  ActiveRecord::Base.establish_connection(
      :adapter => db['MYSQL_ADAPTER'],
      :host => db['MYSQL_HOST'],
      :username=> db['MYSQL_USER'],
      :password=> db['MYSQL_PASSWORD'],
      :database => db['MYSQL_DATABASE']
  )
  ActiveRecord::Tasks::DatabaseTasks.migrate
  SecretsManager.unset(db)
end

