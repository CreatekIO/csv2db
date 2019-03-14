module Csv2db
  class Engine < Rails::Engine
    isolate_namespace Csv2db

    # See https://content.pivotal.io/blog/leave-your-migrations-in-your-rails-engines
    initializer :append_migrations do |app|
      unless app.root.to_s.match(root.to_s)
        config.paths['db/migrate'].expanded.each do |expanded_path|
          app.config.paths['db/migrate'] << expanded_path
        end
      end
    end
  end
end
