require 'sinatra'
require 'yajl'
require 'restclient'

post "/heroku/resources" do
  resp = { :id => 123, :config => { "FOO" => "bar" } }
  #resp = { :id => 123 }
  Yajl::Encoder.encode(resp)
end

delete "/heroku/resources/:id" do
  "ok"
end
