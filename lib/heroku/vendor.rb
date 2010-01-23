require 'yajl'

module Heroku

  module Vendor

    class Checkable
      class CheckFailure < StandardError ; end

      def initialize(data)
        @data = data
      end

      def check!
        data = if @data.is_a? Hash
          @data
        else
          Yajl::Parser.parse(@data)
        end
        validate(data)
      rescue Yajl::ParseError => boom
        errors boom.message
      end

      def desc(msg, o=nil, &blk)
        temp, @desc = @desc, "#{@desc}#{msg} "
        yield o
      rescue CheckFailure => boom
        errors boom.message
      ensure
        @desc = temp
      end

      def check(msg)
        raise CheckFailure, "#{@desc}#{msg}" if !yield
      end

      def errors(msg=nil)
        @errors ||= [] if msg
        @errors << msg if msg
        @errors
      end

      def errors?
        return false if errors.nil?
        errors.empty?
      end

    end

    class Manifest < Checkable

      def self.init(filename)
        manifest = {
          "name" => "youraddon",

          "api" => {
            "test" => "http://localhost:4567/",
            "production" => "https://yourapp.com/"
          },

          "plans" => [
            {
              "name" => "Basic",
              "price" => "0",
              "price_unit" => "month"
            }
          ]
        }

        json = Yajl::Encoder.encode(manifest, :pretty => true)
        open(filename, 'w') {|f| f << json }
      end

      def validate(data)

        desc "`api`" do

          check "must exist" do
            data.has_key?("api")
          end

          check "must be a hash" do
            data["api"].is_a?(Hash)
          end

          desc "must have a url for" do

            check "`test`" do
              data["api"].has_key?("test")
            end

            check "`production`" do
              data["api"].has_key?("production")
            end

            check "`production` that is https" do
              url = URI(data["api"]["production"])
              url.scheme == "https"
            end

          end

        end


        desc "`plans`" do

          check "must exist" do
            data.has_key?("plans")
          end

          check "must be an array" do
            data["plans"].is_a?(Array)
          end

          check "must contain at least one plan" do
            data["plans"].size >= 1
          end

          data["plans"].each_with_index do |plan, n|

            desc "at #{n} -", plan do |plan|

              desc "`name`" do
                check "must exist" do
                  plan.has_key?("name")
                end
              end

              desc "`price`" do

                check "must exist" do
                  plan.has_key?("price")
                end

                check "must be an integer" do
                  plan["price"].to_s =~ /^\d+$/
                end

              end

              desc "`price_unit`" do

                check "must exist" do
                  plan.has_key?("price_unit")
                end

                valid_price_units = %w|month dyno_hour|
                check "must be [#{valid_price_units.join("|")}]" do
                  valid_price_units.include?(plan["price_unit"])
                end

              end

            end

          end

        end

      end

    end

    class CreateResponse
    end

  end

end
