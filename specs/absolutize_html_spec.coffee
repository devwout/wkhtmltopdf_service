describe 'absolutize_html', ->

  absolutize_html = require('../lib/absolutize_html')

  describe '.absolutize_url', ->
    absolutize_url = absolutize_html.absolutize_url

    root = 'http://myserver.com'
    path = '/pages/default'

    it 'returns an absolute url as-is', ->
      expect(absolutize_url(root, root, path)).toBe 'http://myserver.com'
      url2 = 'http://myserver.com:3000/interesting/path'
      expect(absolutize_url(url2, root, path)).toBe url2

    it 'returns an absolute https url as-is', ->
      url = 'https://secure.myserver.com:8888/some/doc'
      expect(absolutize_url(url, root, path)).toBe url

    it 'adds the given root url to relative urls starting with /', ->
      url = '/starting/from/root'
      expect(absolutize_url(url, root, path)).toBe 'http://myserver.com/starting/from/root'

    it 'adds the given root url and base path to relative urls not starting with /', ->
      url = 'images/1.png'
      expect(absolutize_url(url, root, path)).toBe 'http://myserver.com/pages/default/images/1.png'

    it 'adds the given root url and base path to relative urls staring with http', ->
      url = 'http/file'
      expect(absolutize_url(url, root, path)).toBe 'http://myserver.com/pages/default/http/file'

    it 'adds the given root url and base path to relative urls starting with ../', ->
      url = '../assets/button.png'
      expect(absolutize_url(url, root, path)).toBe 'http://myserver.com/pages/default/../assets/button.png'

  describe '.absolutize_html', ->

    absolutize_html = require('../lib/absolutize_html').absolutize_html
    url = 'http://myserver.com/pages/default'

    it 'replaces relative urls in image src', ->
      html = '<img src="images/1.png"/>'
      expect(absolutize_html(html, url)).toBe '<img src="http://myserver.com/pages/default/images/1.png"/>'

    it 'replaces relative urls in image src that start with ..', ->
      html = '<img src="../assets/button.png"/>'
      expect(absolutize_html(html, url)).toBe '<img src="http://myserver.com/pages/default/../assets/button.png"/>'

    it 'replaces relative urls in image src that start with /', ->
      html = '<img src="/assets/button.png"/>'
      expect(absolutize_html(html, url)).toBe '<img src="http://myserver.com/assets/button.png"/>'

    it 'does not care about the location of the src attribute in the img tag', ->
      html = '<img alt="I" src="/i.jpg"  />'
      expect(absolutize_html(html, url)).toBe '<img alt="I" src="http://myserver.com/i.jpg"  />'

    it 'replaces multiple occurrences of relative urls in image srcs', ->
      html = 'first <img src="file1"/> \n second <img src="file2"/>'
      expect(absolutize_html(html, url)).toBe(
        'first <img src="http://myserver.com/pages/default/file1"/> \n second <img src="http://myserver.com/pages/default/file2"/>'
      )

    it 'replaces relative urls that start with / in stylesheet href', ->
      html = '<link media="all" type="text/css" charset="utf-8" rel="Stylesheet" href="/stylesheets/print.css" />'
      expect(absolutize_html(html, url)).toBe(
        '<link media="all" type="text/css" charset="utf-8" rel="Stylesheet" href="http://myserver.com/stylesheets/print.css" />'
      )

    it 'replaces multiple occurrences of relative urls in stylesheet hrefs', ->
      html = '<link media="print" href="print.css"/>  \n <link media="screen" href="/style.css">'
      expect(absolutize_html(html, url)).toBe(
        '<link media="print" href="http://myserver.com/pages/default/print.css"/>  \n <link media="screen" href="http://myserver.com/style.css">'
      )
