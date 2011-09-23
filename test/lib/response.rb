Response = Struct.new(:code, :body, :cookies) do
  def json_body
    Yajl::Parser.parse(self.body)
  end
end

