require 'sidekiq'

module Csv2db
  class ImportWorker
    include Sidekiq::Worker
    sidekiq_options retry: true

    def perform(class_name, file_processor_id)
      klass = class_name.constantize
      check_class!(klass)

      klass.find(file_processor_id).process
    end

    private

    def check_class!(klass)
      unless klass.ancestors.include?(::Csv2db::Import)
        raise ArgumentError, 'must include Csv2db::Import'
      end
    end
  end
end
