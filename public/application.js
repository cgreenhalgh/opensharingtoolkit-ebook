
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
  var appCache, delayedLink, onCacheUpdate, pageStack;

  appCache = window.applicationCache;

  onCacheUpdate = function() {
    var bookmark, status;
    bookmark = true;
    status = (function() {
      switch (appCache.status) {
        case appCache.UNCACHED:
          bookmark = false;
          return 'This eBook is not saved; you will need Internet access to view it again';
        case appCache.IDLE:
          return 'Saved for off-Internet use';
        case appCache.UPDATEREADY:
          return '<a href="#reload">Reload the new version</a>';
        case appCache.CHECKING:
        case appCache.DOWNLOADING:
          return 'Checking for a new version';
        case appCache.OBSOLETE:
          return 'obsolete';
        default:
          return 'There unknown (' + appCache.status + ')';
      }
    })();
    console.log('AppCache status = ' + status);
    if (bookmark) {
      status = status + "<br/>Bookmark this page to view it later";
    }
    return $('#cacheFeedback').html(status);
  };

  delayedLink = null;

  pageStack = [];

  $(document).on("mobileinit", function() {
    console.log('mobileinit');
    $.mobile.pushStateEnabled = false;
    $.mobile.ajaxEnabled = false;
    return $.mobile.linkBindingEnabled = false;
  });

  module.exports.init = function() {
    if (appCache == null) {
      console.log('no appCache');
      return false;
    }
    onCacheUpdate();
    $(appCache).bind("cached checking downloading error noupdate obsolete progress updateready", function(ev) {
      console.log('appCache event ' + ev.type + ', status = ' + appCache.status);
      onCacheUpdate();
      return false;
    });
    console.log("mobile config anyway...");
    $.mobile.pushStateEnabled = false;
    $.mobile.ajaxEnabled = false;
    $.mobile.linkBindingEnabled = false;
    $(document).on('click', 'a', function(ev) {
      var activeId, activePage, backUrl, err, href;
      href = $(ev.currentTarget).attr('href');
      if (href.indexOf(':') >= 0 || href.indexOf('//') === 0) {
        console.log("Delayed click " + href);
        activePage = $("body").pagecontainer('getActivePage');
        activeId = activePage.get(0).id;
        pageStack.push(activeId);
        delayedLink = href;
        $('#linkUrl').text(href);
        $("body").pagecontainer('change', '#link', {
          changeHash: false
        });
        return false;
      } else if ($(ev.currentTarget).parents('div[id=link]').length > 0) {
        console.log("click on link page " + href);
        if (pageStack.length > 0) {
          backUrl = '#' + pageStack[pageStack.length - 1];
        } else {
          console.log("pageStack empty!");
          backUrl = '#';
        }
        $("body").pagecontainer('change', backUrl, {
          changeHash: false
        });
        return false;
      } else if (href === '#reload') {
        console.log('Reload...');
        event.preventDefault();
        try {
          window.applicationCache.swapCache();
        } catch (_error) {
          err = _error;
          console.log("error swapping cache: " + err);
        }
        return window.location.reload();
      } else {
        console.log("click " + href);
        return true;
      }
    });
    return $('#linkOpen').on('click', function(ev) {
      var open;
      open = function() {
        if (delayedLink) {
          return window.open(delayedLink);
        }
      };
      setTimeout(open, 100);
      return true;
    });
  };

}).call(this);
}});
