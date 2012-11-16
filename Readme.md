wkhtmltopdf web service
=======================

This web service renders posted HTML to PDF using [wkhtmltopdf](http://code.google.com/p/wkhtmltopdf/).

Because it allows posting of HTML content, it can be used straight from the user's browser 
to render the page he is currently viewing, including DOM modifications made in Javascript.
It can also be used as a backend service, of course.

API
---

    GET /

Show this documentation.

    POST /pdf
 
Get a PDF document with rendered HTML contents.

The post body should contain the following parameters, url encoded.
(content-type application/x-www-form-urlencoded)

Note: Multipart forms are not supported.

* `html` The HTML document to render.
