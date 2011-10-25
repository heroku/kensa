Response = Struct.new(:code, :body, :cookies) do
  def json_body
    Yajl::Parser.parse(self.body)
  rescue Yajl::ParseError
    if !self.body || self.body.empty?
      raise Heroku::Kensa::UserError.new("response body empty")
    else
      raise Heroku::Kensa::UserError.new("Could not parse json: #{self.body}")
    end
  end
end

