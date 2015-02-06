class Authentication < ActiveRecord::Base
  validates_presence_of :client_id, :client_secret, :username, :password, :redirect_uri

  def get_client
    unless access_token.blank? || access_token == 'updating'
      Authentication.connection.execute %Q(UPDATE "authentications" SET "client_count" = "client_count" + 1 WHERE "authentications"."id" = #{id})
      set_instagram_config
      Instagram.client(access_token: access_token)
    else
      raise 'No Access Token'
    end
  end

  def get_access_token
    if access_token != 'updating'
      update(access_token: 'updating')
      set_instagram_config
      update(access_token: InstagramCrawler.get_token(username, password, redirect_uri), client_count: 0)
    else
      raise 'Access Token Updating'
    end
  end

  def self.clear_count
    Authentication.update_all(client_count: 0)
    ClearCountWorker.perform_in(1.hour)
  end

  private
  def set_instagram_config
    return if client_id.nil? or client_secret.nil?
    Instagram.configure do |config|
      config.client_id = client_id
      config.client_secret = client_secret
    end
  end
end
