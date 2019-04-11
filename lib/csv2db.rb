require 'csv2db/version'

module Csv2db
  class Error < StandardError; end
  # Your code goes here...
end

require 'csv2db/rails' if defined?(Rails)
