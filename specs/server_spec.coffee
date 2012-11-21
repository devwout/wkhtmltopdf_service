describe 'server', ->

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
          #expect(res.headers['content-length']).toBe String(Buffer.byteLength(body))
          done()

      it 'returns a 500 error when wkhtmltopdf does not exist in env.PATH', (done)->
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

  it '[AFTER] shuts down the HTTP server', ->
    server.close()
