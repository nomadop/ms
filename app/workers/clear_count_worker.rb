class ClearCountWorker
  include Sidekiq::Worker
  sidekiq_options queue: :phoenix_job

  def perform()
    Authentication.clear_count
  end
end