var fs = require('fs');
var temp = require('temp');
var path = require('path')
var http = require('http');
var url = require('url');
var querystring = require('querystring');
var child_process = require('child_process');

var absolutize_html = require('./lib/absolutize_html').absolutize_html;

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
  var args = optionsFromEnv().concat(['-', '-']);
  var temppath = temp.path('wkhtmltopdf');
  fs.open(temppath, 'w', function(err, fd) {
    // TODO: handle err
    var io_options = {stdio: ['pipe', fd, process.stderr]};
    var child = child_process.spawn(wkhtmltopdf, args, io_options);
    child.on('exit', function(code) {
      if (code === 0) {
        fs.readFile(temppath, function(err, data) {
          // TODO: handle err
          res.writeHead(200, {
            'Content-Type': 'application/pdf',
            'Content-Length': data.length
          });
          res.end(data);
        });
      } else {
        console.log('Error while running wkhtmltopdf: Error ' + code);
        res.writeHead(500, {'Content-Type': 'text/plain'});
        res.end('Error while running wkhtmltopdf');
      }
    });
    child.stdin.on('error', function() { });
    child.stdin.end(html);
  });
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
        var url = post.url;
        if (html) {
          if (url) {
            html = absolutize_html(html, url);
          }
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

