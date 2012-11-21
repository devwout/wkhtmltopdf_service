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

Use from the browser
--------------------

To use this service from the browser, include the following javascript code
and call the `print_pdf` function.

    var print_pdf_url = "http://REPLACE_THIS_WITH_THE_WEBSERVICE_URL/pdf";

    /* Print the page by posting its HTML contents to a HTML->PDF conversion service.
    * To achieve this, a form is dynamically generated and then submitted.
    * The form is added to the document, as IE and FF require it to submit.
    * Tested on IE8, IE9, FF3, Chrome.
     */
    function print_pdf() {
      var form = document.createElement('form');
      var textarea = document.createElement('textarea');
      textarea.name = 'html';
      textarea.value = document.documentElement.innerHTML;
      form.appendChild(textarea);
      form.action = print_pdf_url;
      form.method = 'POST';
      form.setAttribute('style', 'display:none');
      document.body.appendChild(form);
      form.submit();
    }
