require 'test/lib/dependencies'
class SsoTest < Test::Unit::TestCase

  setup do
    @user_id ||= manifest["user_id"] || 123
    @params = { :timestamp => Time.now.to_i,
                :token => make_token(@user_id, manifest["sso_salt"], Time.now.to_i.to_s),
                "nav-data" => "some-nav-data"
              }
  end

  def sso_post?
    manifest["api"]["test"].is_a?(Hash) &&
      manifest["api"]["test"]["sso_url"]
  end

  def sso_url
    if sso_post?
      manifest["api"]["test"]["sso_url"].chomp("/")
    else
      "/heroku/resources"
    end
  end

  def sso_login(params = @params, user_id = @user_id)
    if sso_post?
      post sso_url, params.merge(:id => user_id)
    else
      get "#{sso_url}/#{user_id}", params
    end
  end

  test "validates token" do
    @params[:token] = "foo"
    response = sso_login
    assert_equal 403, response.code, "Signing in via SSO at /heroku/resources/:id must return a 403 if the token is invalid."
  end

  test "validates timestamp" do
    @params[:timestamp] = (Time.now-60*3).to_i
    @params[:token] = make_token(123, "SSO_SALT", @params[:timestamp].to_s)
    response = sso_login
    assert_equal 403, response.code, "Signing in via SSO at /heroku/resources/:id must return a 403 if the timestamp is expired."

    @params[:timestamp] = "foo"
    response = sso_login
    assert_equal 403, response.code, "Signing in via SSO at /heroku/resources/:id must return a 403 if the timestamp is invalid."
  end

  test "logs in" do
    response = sso_login
    assert response.code.to_s.match(/\A2/), "Signing in via SSO at /heroku/resources/:id must return a 2xx response if sign in was valid."
  end

  test "creates the heroku-nav-data cookie" do
    response = sso_login
    assert response.cookies, "SSO sign in should set the heroku-nav-data cookie to the value of the passed nav-data parameter."
    assert_equal @params["nav-data"], response.cookies["heroku-nav-data"], "SSO sign in should set the heroku-nav-data cookie to the value of the passed nav-data parameter."
  end

  test "displays the heroku layout" do
    response = sso_login
    document = Nokogiri::HTML.parse(response.body)
    assert !document.search("div#heroku-header").empty?, "Logged in page should contain the Heroku header."
  end
end
