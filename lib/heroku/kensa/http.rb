require 'restclient'

module Heroku
  module Kensa
    module HTTP

      def get(path, params={})
        path = "#{path}?" + params.map { |k, v| "#{k}=#{v}" }.join("&") unless params.empty?
        request(:get, [], path)
      end

      def post(credentials, path, payload=nil)
        request(:post, credentials, path, payload)
      end

      def put(credentials, path, payload=nil)
        request(:put, credentials, path, payload)
      end

      def delete(credentials, path, payload=nil)
        request(:delete, credentials, path, payload)
      end

      def request(meth, credentials, path, payload=nil)
        code = nil
        body = nil

        begin
          args = [
            { :accept => "application/json" }
          ]
          
          if payload
            args.first[:content_type] = "application/json"
            args.unshift OkJson.encode(payload)
          end

          user, pass = credentials
          body = RestClient::Resource.new(url, user, pass)[path].send(
            meth,
            *args
          ).to_s

          code = 200
        rescue RestClient::ExceptionWithResponse => boom
          code = boom.http_code
          body = boom.http_body
        rescue Errno::ECONNREFUSED
          code = -1
          body = nil
        end

        [code, body]
      end

    end
  end
end
