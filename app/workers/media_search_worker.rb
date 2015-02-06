class MediaSearchWorker
  include Sidekiq::Worker

  def perform(id)
    media_search = MediaSearch.find(id)
    media_search.run
  end
end