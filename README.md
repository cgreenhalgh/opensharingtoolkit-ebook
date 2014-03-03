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
npm install coffee-script stitch express eco
```

Export the assembled application.js:
```
coffee build.coffee
```

Runs as server on [port 9294](http://127.0.0.1:9294) by default:
```
coffee index.coffee
```

