Setup wkhtmltopdf_service
=========================

Main principles
---------------

* Minimal functionality
* Minimal dependencies
* Stateless
* All configuration is done in the environment
* Logging to stdout

wkhtmltopdf
-----------

The service depends on wkhtmltopdf. The command-line utility should be installed
in a directory contained in the `PATH` environment variable.

Configuration
-------------

The following environment variables can be used to configure the service.

* `PORT` TCP port the service should bind to. Defaults to `8779`.

Running
-------

`npm install` installs dependencies.

`npm start` runs the server.
`env PORT=8080 npm start` runs the server on port 8080.
`./env.osx npm start` runs the server with the correct PATH for Mac OS X.

`npm test` runs the test suite.

