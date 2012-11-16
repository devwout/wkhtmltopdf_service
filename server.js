var http = require('http');
var url = require('url');
var querystring = require('querystring');
var child_process = require('child_process');

var host = '0.0.0.0'
var port = process.env.PORT || 8779;

function wkhtmltopdf_command() {
  // TODO: wkhtmltopdf should just be present in env.PATH (we could supply an environment script, however)
  var command = '/Applications/wkhtmltopdf.app/Contents/MacOS/wkhtmltopdf'
  return command;
}

exports.server = http.createServer(function (req, res) {
  u = url.parse(req.url);
  if (req.method == 'POST' && u.pathname == '/pdf') {
    var body = '';
    req.on('data', function(data) { body += data });
    req.on('end', function() {
      var post = querystring.parse(body);
      var html = post.html;
      if (html) {
        var child = child_process.spawn(wkhtmltopdf_command(), ['-', '-']);
        var buffers = [];
        child.stdout.on('data', function(data) { buffers.push(data) });
        child.on('exit', function(code) {
          if (code === 0) {
            var buffer = Buffer.concat(buffers);
            res.writeHead(200, {'Content-Type': 'application/pdf'}); // TODO: Content-Length
            res.end(buffer);
          } // TODO: else 500 & log
        });
        child.stdin.end(html);
      } else {
        res.writeHead(400, {'Content-Type': 'text/plain'});
        res.end('Form parameter "html" required');
      }
    });
  } else {
    res.writeHead(404, {'Content-Type': 'text/plain'});
    res.end('Not found');
  }
}).listen(port, host);

console.log('Listening on http://'+host+':'+port);

