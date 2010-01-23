require 'sinatra'
require 'yajl'
require 'restclient'

post "/heroku/apps" do
  resp = { :id => 123, :config => { "FOO" => "bar" } }
  #resp = { :id => 123 }
  Yajl::Encoder.encode(resp)
end

delete "/heroku/apps/:id" do
  "ok"
end
