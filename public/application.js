
(function(/*! Stitch !*/) {
  if (!this.require) {
    var modules = {}, cache = {}, require = function(name, root) {
      var path = expand(root, name), module = cache[path], fn;
      if (module) {
        return module.exports;
      } else if (fn = modules[path] || modules[path = expand(path, './index')]) {
        module = {id: path, exports: {}};
        try {
          cache[path] = module;
          fn(module.exports, function(name) {
            return require(name, dirname(path));
          }, module);
          return module.exports;
        } catch (err) {
          delete cache[path];
          throw err;
        }
      } else {
        throw 'module \'' + name + '\' not found';
      }
    }, expand = function(root, name) {
      var results = [], parts, part;
      if (/^\.\.?(\/|$)/.test(name)) {
        parts = [root, name].join('/').split('/');
      } else {
        parts = name.split('/');
      }
      for (var i = 0, length = parts.length; i < length; i++) {
        part = parts[i];
        if (part == '..') {
          results.pop();
        } else if (part != '.' && part != '') {
          results.push(part);
        }
      }
      return results.join('/');
    }, dirname = function(path) {
      return path.split('/').slice(0, -1).join('/');
    };
    this.require = function(name) {
      return require(name, '');
    }
    this.require.define = function(bundle) {
      for (var key in bundle)
        modules[key] = bundle[key];
    };
  }
  return this.require.define;
}).call(this)({"app": function(exports, require, module) {(function() {
  var appCache, onCacheUpdate;

  appCache = window.applicationCache;

  onCacheUpdate = function() {
    var status;
    status = (function() {
      switch (appCache.status) {
        case appCache.UNCACHED:
          return 'uncached';
        case appCache.IDLE:
          return 'idle';
        case appCache.CHECKING:
          return 'checking';
        case appCache.DOWNLOADING:
          return 'downloading';
        case appCache.UPDATEREADY:
          return 'updateready';
        case appCache.OBSOLETE:
          return 'obsolete';
        default:
          return 'unknown (' + appCache.status + ')';
      }
    })();
    console.log('AppCache status = ' + status);
    $('#cacheFeedback').html('Cache ' + status);
    if (appCache.status === appCache.UPDATEREADY) {
      return $(":mobile-pagecontainer").pagecontainer("change", "#updateready", {
        changeHash: true,
        reload: true
      });
    }
  };

  module.exports.init = function() {
    if (appCache == null) {
      console.log('no appCache');
      $('#cacheFeedback').html('Sorry, cannot cache on this device');
      return false;
    }
    onCacheUpdate();
    return $(appCache).bind("cached checking downloading error noupdate obsolete progress updateready", function(ev) {
      console.log('appCache event ' + ev.type + ', status = ' + appCache.status);
      onCacheUpdate();
      return false;
    });
  };

}).call(this);
}});
