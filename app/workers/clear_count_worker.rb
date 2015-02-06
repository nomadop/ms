class ClearCountWorker
  include Sidekiq::Worker

  def perform()
    Authentication.clear_count
  end
end