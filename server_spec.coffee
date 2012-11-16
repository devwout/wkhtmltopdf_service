describe 'server', ->

  http = require('http')
  server = require('./server').server
  
  get = (path, callback)-> req('GET', path, null, callback)

  req = (method, path, body, callback)->
    addr = server.address()
    r = http.request method: method, hostname: addr.address, port: addr.port, path: path, (res)->
      buf = ''
      res.on('data', (s)-> buf = buf + s)
      res.on('end', -> callback(res, buf))
    r.end(body)

  describe 'GET randomurl', ->
    it 'returns a 404 error', (done)->
      get '/randomurl', (res, body)->
        expect(res.statusCode).toBe 404
        expect(body).toBe 'Not found'
        done()

  describe 'GET /', ->
    xit 'returns some documentation on the web service API' # TODO

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
        req 'POST', '/pdf', '', (res, body)->
          expect(res.statusCode).toBe 400
          expect(body).toBe 'Form parameter "html" required'
          done()

    describe 'with a html parameter in the body', ->
      it 'returns a 200 with Content-Type application/pdf', (done)->
        req 'POST', '/pdf', 'html=<body>Some Juicy Html</body>', (res, body)->
          expect(res.statusCode).toBe 200
          expect(res.headers['content-type']).toBe 'application/pdf'
          expect(body.length).not.toBe 0
          #expect(res.headers['content-length']).toBe String(Buffer.byteLength(body))
          done()

  it '[AFTER] shuts down the HTTP server', ->
    server.close()
