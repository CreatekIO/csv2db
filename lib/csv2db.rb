require 'csv2db/version'
require 'csv2db/config'

module Csv2db
  class Error < StandardError; end

  class << self
    def config
      Config.instance
    end

    def configure
      yield(config)
    end
  end
end

require 'csv2db/rails' if defined?(Rails)
