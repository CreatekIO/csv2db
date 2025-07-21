require 'singleton'

module Csv2db
  class Config
    include Singleton

    attr_writer :storage_adapter, :local_storage_host, :file_attachment_name

    def storage_adapter
      @storage_adapter ||= :dragonfly
      ActiveSupport::StringInquirer.new(@storage_adapter.to_s)
    end

    def local_storage_host
      @local_storage_host ||= ''
    end

    def file_attachment_name
      @file_attachment_name ||= :file_attachment
    end
  end
end
