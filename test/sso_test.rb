$:.unshift(File.expand_path("../..",__FILE__))
require 'test/lib/dependencies'
class SsoTest < Test::Unit::TestCase

  def setup
    super
    @user_id ||= manifest["user_id"] || 123
    @time = Time.now.to_i
    @params = { :timestamp => @time,
                :token => make_token(@user_id, manifest['api']["sso_salt"], @time.to_s),
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

  def test_validates_token
    @params[:token] = "foo"
    response = sso_login
    assert_equal 403, response.code, "Signing in via SSO at /heroku/resources/:id must return a 403 if the token is invalid."
  end

  def test_validates_timestamp
    @params[:timestamp] = (Time.now-60*3).to_i
    @params[:token] = make_token(123, "SSO_SALT", @params[:timestamp].to_s)
    response = sso_login
    assert_equal 403, response.code, "Signing in via SSO at /heroku/resources/:id must return a 403 if the timestamp is expired."

    @params[:timestamp] = "foo"
    response = sso_login
    assert_equal 403, response.code, "Signing in via SSO at /heroku/resources/:id must return a 403 if the timestamp is invalid."
  end

  def test_logs_in
    response = sso_login
    assert response.code.to_s.match(/\A2/), "Signing in via SSO at /heroku/resources/:id must return a 2xx response if sign in was valid."
  end

  def test_creates_the_heroku_nav_data_cookie
    response = sso_login  

    assert response.cookies, "SSO sign in should set the heroku-nav-data cookie to the value of the passed nav-data parameter."
    assert_equal @params["nav-data"], response.cookies["heroku-nav-data"], "SSO sign in should set the heroku-nav-data cookie to the value of the passed nav-data parameter."
  end

  def test_displays_the_heroku_layout
    response = sso_login
    document = Nokogiri::HTML.parse(response.body)
    assert !document.search("div#heroku-header").empty?, "Logged in page should contain the Heroku header."
  end
end
