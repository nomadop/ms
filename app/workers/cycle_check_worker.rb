class CycleCheckWorker
  include Sidekiq::Worker

  def perform()
    SearchArea.cycle_check
  end
end