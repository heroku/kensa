Response = Struct.new(:code, :body, :cookies) do
  def json_body
    if !self.body || self.body.empty?
      raise Heroku::Kensa::UserError.new("response body empty")
    end
    Yajl::Parser.parse(self.body)
  end
end

