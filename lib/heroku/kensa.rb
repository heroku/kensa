base_path = File.dirname(__FILE__)
%w{http manifest check sso post_proxy}.each do |lib|
  require "#{base_path}/kensa/#{lib}"
end

module Heroku
  module Kensa
    VERSION = "1.1.4"
  end
end
