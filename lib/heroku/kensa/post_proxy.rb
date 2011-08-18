require 'webrick'

class Heroku::Kensa::PostProxy < WEBrick::HTTPServer
  def initialize(params = {})
    @params = params
    @id = params.delete :id
    @host = params.delete :host
    super :Port => params.delete(:port), :AccessLog => WEBrick::Log.new(StringIO.new),
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
          <form action="#{@host}/heroku/resources/#{@id}" method="POST">
            #{ @params.map do |key, value|
                %|<input type="hidden" name="#{key}" value="#{value}" />|
               end.join("\n")  
             }
          </form>
        </body>
      </html>
    HTML
    res["Content-Lengh"] = res.body.size
    @status = :Shutdown
  end
end
