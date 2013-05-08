require_relative 'helper'

class BootstrapTest < MiniTest::Unit::TestCase
  include Heroku::Kensa

  def setup
    stub(Git).run
    any_instance_of Client do |client|
      stub(client).init
    end
    stub(Dir).chdir
  end

  def test_requires_an_app_name
    assert_raise Client::CommandInvalid do
      kensa "bootstrap my_addon"
    end
  end

  def test_requires_a_template
    assert_raise Client::CommandInvalid do
      kensa "bootstrap --template foo"
    end
  end

  def test_assumes_the_heroku_template
    kensa "bootstrap my_addon --template sinatra"
    assert_received Git do |git|
      git.run("git clone git://github.com/heroku/kensa-create-sinatra my_addon")
    end
  end

  def test_assumes_github_is_the_repo_host
    kensa "bootstrap my_addon --template heroku/sinatra"
    assert_received Git do |git|
      git.run("git clone git://github.com/heroku/sinatra my_addon")
    end
  end

  def test_allows_a_full_git_url
    kensa "bootstrap my_addon --template git://heroku.com/sinatra.git"
    assert_received Git do |git|
      git.run("git clone git://heroku.com/sinatra.git my_addon")
    end
  end
end
