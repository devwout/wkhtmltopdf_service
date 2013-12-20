describe 'server', ->

  fs = require('fs')
  http = require('http')
  server = require('../server').server
  
  get = (path, callback)-> req('GET', path, null, callback)
  post = (path, body, callback)-> req('POST', path, body, callback)

  req = (method, path, body, callback)->
    addr = server.address()
    r = http.request method: method, hostname: addr.address, port: addr.port, path: path, (res)->
      buf = ''
      res.on('data', (s)-> buf = buf + s)
      res.on('end', -> callback(res, buf))
    r.end(body)

  beforeEach ->
    process.env.PATH = __dirname + '/stubs/ok'
    delete process.env.WKHTMLTOPDF_DEFAULT_OPTIONS

  describe 'GET randomurl', ->
    it 'returns a 404 error', (done)->
      get '/randomurl', (res, body)->
        expect(res.statusCode).toBe 404
        expect(body).toBe 'Not found'
        done()

  describe 'GET /', ->
    it 'returns some documentation on the web service API', (done)->
      get '/', (res, body)->
        expect(res.statusCode).toBe 200
        expect(res.headers['content-type']).toBe 'text/plain'
        expect(body).toMatch /POST \/pdf/
        done()
  
  describe 'POST /', ->
    it 'returns a 405 error', (done)->
      post '/', '', (res, body)->
        expect(res.statusCode).toBe 405
        expect(body).toBe 'Only GET method allowed'
        done()

  describe 'GET /pdf', ->
    it 'returns a 405 error', (done)->
      get '/pdf', (res, body)->
        expect(res.statusCode).toBe 405
        expect(body).toBe 'Only POST method allowed'
        done()

  describe 'PUT /pdf', ->
    it 'returns a 405 error', (done)->
      req 'PUT', '/pdf', '', (res, body)->
        expect(res.statusCode).toBe 405
        expect(body).toBe 'Only POST method allowed'
        done()

  describe 'POST /pdf', ->
    describe 'without parameters in the body', ->
      it 'returns a 400 error', (done)->
        post '/pdf', '', (res, body)->
          expect(res.statusCode).toBe 400
          expect(body).toBe 'Form parameter "html" required'
          done()

    describe 'with a html parameter in the body', ->
      html = 'html=<body>Some Juicy Html</body>'

      it 'returns a 200 with Content-Type application/pdf', (done)->
        post '/pdf', html, (res, body)->
          expect(res.statusCode).toBe 200
          expect(res.headers['content-type']).toBe 'application/pdf'
          expect(body.length).not.toBe 0
          expect(body).toEqual 'response_from_ok_stub\n'
          expect(res.headers['content-length']).toBe '22'
          done()

      it 'returns a 200 with the unmodified binary PDF output', (done)->
        process.env.PATH = __dirname + '/stubs/binary'

        post '/pdf', html, (res, body)->
          expect(res.statusCode).toBe 200
          expect(res.headers['content-length']).toBe '29911'
          expect(body).toEqual fs.readFileSync(__dirname + '/stubs/binary/binary_data').toString()
          done()

      describe 'when env.WKHTMLTOPDF_DEFAULT_OPTIONS is unset', ->
        it 'runs wkhtmltopdf without extra options', (done)->
          process.env.PATH = __dirname + '/stubs/options'

          post '/pdf', html, (res, body)->
            expect(res.statusCode).toBe 200
            expect(body).toBe '2\n-\n-\n'
            done()

      describe 'when env.WKHTMLTOPDF_DEFAULT_OPTIONS is set', ->
        it 'runs wkhtmltopdf with the options present in env.WKHTMLTOPDF_DEFAULT_OPTIONS', (done)->
          process.env.PATH = __dirname + '/stubs/options'
          process.env.WKHTMLTOPDF_DEFAULT_OPTIONS = '--some-random-option --given-in-the-environment'

          post '/pdf', html, (res, body)->
            expect(res.statusCode).toBe 200
            expect(body).toBe '4\n--some-random-option\n--given-in-the-environment\n-\n-\n'
            done()

      describe 'when env.WKHTMLTOPDF_DEFAULT_OPTIONS is set to an empty string', ->
        it 'runs wkhtmltopdf with the options present in env.WKHTMLTOPDF_DEFAULT_OPTIONS', (done)->
          process.env.PATH = __dirname + '/stubs/options'
          process.env.WKHTMLTOPDF_DEFAULT_OPTIONS = ''

          post '/pdf', html, (res, body)->
            expect(res.statusCode).toBe 200
            expect(body).toBe '2\n-\n-\n'
            done()

      describe 'when env.WKHTMLTOPDF_ALLOWED_OPTIONS is set', ->
        describe 'and no extra http parameters are provided', ->
          it 'runs wkhtmltopdf with the options present in env.WKHTMLTOPDF_DEFAULT_OPTIONS', (done)->
            process.env.PATH = __dirname + '/stubs/options'
            process.env.WKHTMLTOPDF_ALLOWED_OPTIONS = '--footer-left --header-left'
            process.env.WKHTMLTOPDF_DEFAULT_OPTIONS = '--some-random-option'

            post '/pdf', html, (res, body)->
              expect(res.statusCode).toBe 200
              expect(body).toBe '3\n--some-random-option\n-\n-\n'
              done()

        describe 'and extra allowed options are given as http parameters', ->
          it 'runs wkhtmltopdf with the options present in env.WKHTMLTOPDF_DEFAULT_OPTIONS', (done)->
            process.env.PATH = __dirname + '/stubs/options'
            process.env.WKHTMLTOPDF_ALLOWED_OPTIONS = '--footer-left --header-left'
            process.env.WKHTMLTOPDF_DEFAULT_OPTIONS = '--some-random-option'

            params = html + '&--footer-left=this%20is%20awesome&--header-left=x&--non-existing=x'

            post '/pdf', params, (res, body)->
              expect(res.statusCode).toBe 200
              expect(body).toBe '7\n--some-random-option\n--footer-left\nthis is awesome\n--header-left\nx\n-\n-\n'
              done()

          it 'allows options without values', (done)->
            process.env.PATH = __dirname + '/stubs/options'
            process.env.WKHTMLTOPDF_ALLOWED_OPTIONS = '--some-option'

            params = html + '&--some-option='

            post '/pdf', params, (res, body)->
              expect(res.statusCode).toBe 200
              expect(body).toBe '3\n--some-option\n-\n-\n'
              done()

          it 'does not allow repeated options (for now)', (done)->
            process.env.PATH = __dirname + '/stubs/options'
            process.env.WKHTMLTOPDF_ALLOWED_OPTIONS = '--footer-left --header-left'

            params = html + '&--footer-left=1&footer-left=2'

            post '/pdf', params, (res, body)->
              expect(res.statusCode).toBe 200
              expect(body).toBe '4\n--footer-left\n1\n-\n-\n'
              #expect(body).toBe '6\n--footer-left\n1\n--footer-left\n2\n-\n-\n'
              done()

      # FIXME: when encountering this, nodejs v0.10.18 exits, instead of returning 500.
      xit 'returns a 500 error when wkhtmltopdf does not exist in env.PATH', (done)->
        process.env.PATH = ''

        spyOn(process.stdout, 'write')

        post '/pdf', html, (res, body)->
          expect(res.statusCode).toBe 500
          expect(res.headers['content-type']).toBe 'text/plain'
          expect(body).toBe 'Error while running wkhtmltopdf'
          expect(process.stdout.write).toHaveBeenCalled()
          expect(process.stdout.write.mostRecentCall.args).toMatch /Error 127/
          done()

      it 'returns a 500 error when wkhtmltopdf returns a nonzero status code', (done)->
        process.env.PATH = __dirname + '/stubs/fail'

        spyOn(process.stdout, 'write')

        post '/pdf', html, (res, body)->
          expect(res.statusCode).toBe 500
          expect(res.headers['content-type']).toBe 'text/plain'
          expect(body).toBe 'Error while running wkhtmltopdf'
          expect(process.stdout.write).toHaveBeenCalled()
          expect(process.stdout.write.mostRecentCall.args).toMatch /Error 5/
          done()

    describe 'with a html and url parameter in the body', ->
      html = 'html=<body>Some Juicy Html <img src="relative/page"/></body>&url=http://test.com/page'

      it 'replaces relative image sources in the html with absolute onces before sending it to wkhtmltopdf', (done)->
        process.env.PATH = __dirname + '/stubs/html'

        post '/pdf', html, (res, body)->
          expect(res.statusCode).toBe 200
          expect(body).toBe '<body>Some Juicy Html <img src="http://test.com/page/relative/page"/></body>'
          done()

  it '[AFTER] shuts down the HTTP server', ->
    server.close()
