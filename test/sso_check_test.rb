require 'test/libs'

class Response < Struct.new(:code, :body, :json_body); end

class SsoCheckTest < Test::Unit::TestCase

  def make_token(id, salt, timestamp)
    Digest::SHA1.hexdigest([id, salt, timestamp].join(':'))
  end

  def get(path, params = {})
    puts "\n\n\n\n\n\n#{base_url}\n\n\n\n\n"
    response = RestClient.get("#{base_url}#{path}", :params => params)
  rescue RestClient::Forbidden
    Response.new(403)
  end

  def base_url
    manifest["api"]["test"].chomp("/")
  end

  def manifest
    return @manifest if @manifest
    @manifest ||= $manifest || Heroku::Kensa::Manifest.new.skeleton
  end

  context "via GET" do
    setup do
      user_id ||= manifest["user_id"] || 123
      @params = { :timestamp => Time.now.to_i,
                  :token => make_token(user_id, manifest["sso_salt"], Time.now.to_i.to_s),
                  "nav-data" => "some-nav-data"
                }
    end

    test "validates token" do
      @params[:token] = "foo"
      response = get "/heroku/resources/123", @params
      assert_equal 403, response.code, "FAILURE: Signing in via SSO at /heroku/resources/:id must return a 403 if the token is invalid."
    end

    test "validates timestamp" do
      @params[:timestamp] = (Time.now-60*3).to_i
      @params[:token] = make_token(123, "SSO_SALT", @params[:timestamp].to_s)
      response = get "/heroku/resources/123", @params
      assert_equal 403, response.code, "FAILURE: Signing in via SSO at /heroku/resources/:id must return a 403 if the timestamp is expired."

      @params[:timestamp] = "foo"
      response = get "/heroku/resources/123", @params
      assert_equal 403, response.code, "FAILURE: Signing in via SSO at /heroku/resources/:id must return a 403 if the timestamp is invalid."
    end

    test "logs in" do
      response = get "/heroku/resources/123", @params
      assert response.code.to_s.match(/\A2/), "FAILURE: Signing in via SSO at /heroku/resources/:id must return a 2xx response if sign in was valid."
    end

    test "creates the heroku-nav-data cookie" do
      response = get "/heroku/resources/123", @params
      assert_equal @params["nav-data"], response.cookies["heroku-nav-data"], "FAILURE: SSO sign in should set the heroku-nav-data cookie to the value of the passed nav-data parameter."
    end

    test "displays the heroku layout" do
      response = get "/heroku/resources/123", @params
      document = Nokogiri::HTML.parse(response.body)
      assert !document.search("div#heroku-header").empty?, "FAILURE: Logged in page should contain the Heroku header."
    end
  end
end
