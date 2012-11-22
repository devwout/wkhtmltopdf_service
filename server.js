var fs = require('fs');
var path = require('path')
var http = require('http');
var url = require('url');
var querystring = require('querystring');
var child_process = require('child_process');

var host = '0.0.0.0'
var port = process.env.PORT || 8779;

var wkhtmltopdf = 'wkhtmltopdf' // command to execute
var documentation = fs.readFileSync(path.join(__dirname, 'Readme.md'));

function optionsFromEnv() {
  var options = process.env.WKHTMLTOPDF_DEFAULT_OPTIONS;
  if (options) {
    return options.split(' ');
  } else {
    return [];
  }
}

function handleHtmlToPdf(html, res) {
  var arguments = optionsFromEnv().concat(['-', '-']);
  var io_options = {stdio: ['pipe', 'pipe', process.stderr]};
  var child = child_process.spawn(wkhtmltopdf, arguments, io_options);
  var buffers = [];
  child.stdout.on('data', function(data) { buffers.push(data) });
  child.on('close', function(code) {
    if (code === 0) {
      var buffer = Buffer.concat(buffers);
      res.writeHead(200, {
        'Content-Type': 'application/pdf',
        'Content-Length': buffer.length
      });
      res.end(buffer);
    } else {
      console.log('Error while running wkhtmltopdf: Error ' + code);
      res.writeHead(500, {'Content-Type': 'text/plain'});
      res.end('Error while running wkhtmltopdf');
    }
  });
  child.stdin.on('error', function() { });
  child.stdin.end(html);
}

exports.server = http.createServer(function (req, res) {
  u = url.parse(req.url);
  if (u.pathname == '/') {
    if (req.method == 'GET') {
      res.writeHead(200, {'Content-Type': 'text/plain'});
      res.end(documentation);
    } else {
      res.writeHead(405, {'Content-Type': 'text/plain'});
      res.end('Only GET method allowed');
    }
  } else if (u.pathname == '/pdf') {
    if (req.method == 'POST') {
      var body = '';
      req.on('data', function(data) { body += data });
      req.on('end', function() {
        var post = querystring.parse(body);
        var html = post.html;
        if (html) {
          handleHtmlToPdf(html, res);
        } else {
          res.writeHead(400, {'Content-Type': 'text/plain'});
          res.end('Form parameter "html" required');
        }
      });
    } else {
      res.writeHead(405, {'Content-Type': 'text/plain'});
      res.end('Only POST method allowed');
    }
  } else {
    res.writeHead(404, {'Content-Type': 'text/plain'});
    res.end('Not found');
  }
}).listen(port, host);

console.log('Listening on http://'+host+':'+port);

