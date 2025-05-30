require 'bundler/setup'
require 'byebug'
require 'mysql2'
require 'logger'
require 'rails/all'
require 'csv2db'
require_relative '../app/models/concerns/csv2db/import'
require_relative '../app/workers/csv2db/import_worker'
require_relative '../app/models/concerns/csv2db/dragonfly_adapter'
require_relative '../app/models/concerns/csv2db/active_storage_adapter'

ENV['RAILS_ENV'] ||= 'test'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

db_config = {
  database: 'csv2db_test',
  adapter: 'mysql2',
  encoding: 'utf8mb4',
  pool: 5,
  host: ENV['DB_HOST'],
  username: ENV['DB_USERNAME'],
  password: ENV['DB_PASSWORD']
}.freeze

ActiveRecord::Base.logger = Logger.new(File.expand_path('../log/test.log', __dir__))
ActiveRecord::Base.establish_connection(db_config)

require 'active_record/tasks/database_tasks'

ActiveRecord::Tasks::DatabaseTasks.tap do |tasks|
  begin
    ActiveRecord::Base.connection
  rescue
    # Database doesn't exist, create it
    tasks.create(db_config.stringify_keys)
  end

  tasks.migrations_paths = [File.expand_path('../db/migrate', __dir__)]
  tasks.migrate rescue nil
end

Dragonfly.app.configure do
  datastore :file, root_path: 'tmp/dragonfly'
end
