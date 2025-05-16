require 'singleton'

module Csv2db
  class Config
    include Singleton

    attr_writer :storage_adapter

    def storage_adapter
      @storage_adapter ||= :dragonfly
      ActiveSupport::StringInquirer.new(@storage_adapter.to_s)
    end
  end
end
