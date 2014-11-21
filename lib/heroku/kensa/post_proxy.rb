require 'webrick'

class Heroku::Kensa::PostProxy < WEBrick::HTTPServer
  def initialize(sso)
    @params = sso.query_params
    @sso = sso
    super :Port => sso.proxy_port, :AccessLog => WEBrick::Log.new(StringIO.new),
            :Logger => WEBrick::Log.new(StringIO.new)
  end

  def service(req, res)
    res.status = 200
    res.body = <<-HTML
      <html>
        <head>
          <script type="text/javascript">
            window.onload = function() { document.forms[0].submit() }
          </script>
        </head>
        <body>
          <form action="#{@sso.post_url}" method="POST">
            #{ @params.map do |key, value|
                %|<input type="hidden" name="#{key}" value="#{value}" />|
               end.join("\n")
             }
          </form>
        </body>
      </html>
    HTML
    res["Content-Length"] = res.body.size
    @status = :Shutdown
  end
end
