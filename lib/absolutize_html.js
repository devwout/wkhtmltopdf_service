var parse = require('url').parse;

exports.absolutize_url = function(url, root_url, base_path) {
  if (/^https?:/.test(url)) {
    return url;
  } else if (/^\//.test(url)) {
    return root_url + url;
  } else {
    return root_url + base_path + '/' + url;
  }
}

exports.absolutize_html = function(html, base_url) {
  var parsed_url = parse(base_url);
  var root_url = parsed_url.protocol + '//' + parsed_url.host;

  html = html.replace(/<img .*src="(.+)"/g, function(img_tag, url) {
    return img_tag.replace(url, exports.absolutize_url(url, root_url, parsed_url.path));
  });
  html = html.replace(/<link .*href="(.+)"/g, function(link_tag, url) {
    return link_tag.replace(url, exports.absolutize_url(url, root_url, parsed_url.path));
  });
  return html;
}
