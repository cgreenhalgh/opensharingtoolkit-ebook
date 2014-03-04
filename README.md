opensharingtoolkit-ebook
========================

eBook skeleton (HTML5-based) and tools for OpenSharingToolkit.

You'll need npm, node, coffescript, e.g. (ubuntu 10.x)
```
sudo apt-get install npm
sudo apt-get install nodejs-legacy

sudo npm install -g coffee-script
```
Get dependencies:
```
npm install coffee-script stitch express eco unzip xml2js
```

(Re)build the ebook generic application.js:
```
coffee build.coffee
```

Convert an `.epub` eBook exported/published from (Booktype)[http://www.sourcefabric.org/en/booktype/] (tested with version 1.6.1.):
```
coffee epub2html.coffee EPUBFILE DIRNAME
```
Note: assumes `DIRNAME` will be a sub-directory of `public/` when served (has relative references to javascript, css, etc.).

Runs as server on [port 9294](http://127.0.0.1:9294) by default:
```
coffee index.coffee
```

