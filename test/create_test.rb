require 'test/helper'

class CreateTest < Test::Unit::TestCase
  include Heroku::Kensa

  def setup
    stub(Git).run
  end

  def test_requires_app_name
    assert_raise Client::CommandInvalid do
      kensa "create my_addon"
    end
  end

  def test_requires_template
    assert_raise Client::CommandInvalid do
      kensa "create --template foo"
    end
  end

  def test_assumes_heroku_template
    kensa "create my_addon --template sinatra"
    assert_received Git do |git|
      git.run("git clone git://github.com/heroku/kensa-create-sinatra my_addon")
    end
  end

  def test_assumes_github
    kensa "create my_addon --template heroku/sinatra"
    assert_received Git do |git|
      git.run("git clone git://github.com/heroku/sinatra my_addon")
    end
  end

  def test_allows_full_url
    kensa "create my_addon --template git://heroku.com/sinatra.git"
    assert_received Git do |git|
      git.run("git clone git://heroku.com/sinatra.git my_addon")
    end
  end
end
