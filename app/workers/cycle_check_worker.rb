class CycleCheckWorker
  include Sidekiq::Worker
  sidekiq_options queue: :phoenix_job

  def perform()
    SearchArea.cycle_check
  end
end