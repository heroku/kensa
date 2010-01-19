require 'yajl'

module Heroku

  module Vendor

    class Manifest
      def initialize(man)
        @man = man
      end

      def check!
        data = Yajl::Parser.parse(@man)
      rescue Yajl::ParseError => boom
        errors boom.message
      end

      def errors(msg=nil)
        @errors ||= [] if msg
        @errors << msg if msg
        @errors
      end

    end

  end
end
