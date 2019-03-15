require 'sidekiq'

module Csv2db
  class ImportWorker
    include Sidekiq::Worker
    sidekiq_options retry: true

    def perform(file_processor_id)
      ::Csv2db::Import.find(file_processor_id).process
    end
  end
end
