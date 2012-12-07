require 'ostruct'

AIOSettings = OpenStruct.new(
  env: ENV['KENSA_ENV'] || 'production',
  oauth_host: ENV['KENSA_HOST'] || 'https://www.action.io',
  oauth_client_id: ENV['KENSA_ID'] || 'production-client-id',
  oauth_client_secret: ENV['KENSA_SECRET'] || 'production-secret'
) unless defined?(AIOSettings)
