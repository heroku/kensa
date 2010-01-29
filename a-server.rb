require 'sinatra'
require 'yajl'
require 'restclient'

post "/heroku/apps" do
  request.body.rewind
  input = Yajl::Parser.parse(request.body.read)
  resp = { :id => 123, :config => { "FOO" => "bar" } }
  #resp = { :id => 456 }
  json = Yajl::Encoder.encode(resp)
  Thread.new do
    sleep 2
    p input
    RestClient.put(input["callback_url"], json)
  end
  "{}"
end

delete "/heroku/apps/:id" do
  "ok"
end
