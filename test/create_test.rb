require_relative 'helper'

class CreateTest < Test::Unit::TestCase
  include Heroku::Kensa

  def setup
    stub(Git).run
    any_instance_of Client do |client|
      stub(client).init
    end
    stub(Dir).chdir
  end

  context "bootstrapping an add-on" do
    test "requires an app name" do
      assert_raise Client::CommandInvalid do
        kensa "bootstrap my_addon"
      end
    end

    test "requires a template" do
      assert_raise Client::CommandInvalid do
        kensa "bootstrap --template foo"
      end
    end

    test "assumes the Heroku template" do
      kensa "bootstrap my_addon --template sinatra"
      assert_received Git do |git|
        git.run("git clone git://github.com/heroku/kensa-create-sinatra my_addon")
      end
    end

    test "assumes GitHub is the repo host" do
      kensa "bootstrap my_addon --template heroku/sinatra"
      assert_received Git do |git|
        git.run("git clone git://github.com/heroku/sinatra my_addon")
      end
    end

    test "allows a full git URL" do
      kensa "bootstrap my_addon --template git://heroku.com/sinatra.git"
      assert_received Git do |git|
        git.run("git clone git://heroku.com/sinatra.git my_addon")
      end
    end
  end
end
