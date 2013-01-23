var availigoQTag = (function(){
  var _scriptRequestUrl = '${scriptRequestUrl}';
  var _logUrl = '${scriptRootUrl}/log.js';
  var _isDraft = ${isDraft};
  
  var _addScript = function(src) {
    setTimeout(function(){
      var scriptTag = document.createElement('script');
      scriptTag.setAttribute('type', 'text/javascript');
      scriptTag.setAttribute('src', src);
      document.getElementsByTagName('head')[0].appendChild(scriptTag);
    }, 50);
  };
  
  var _isDraftRequested = function() {
    var regex = new RegExp("[\\?&]__avail_draft=([^&#]*)");
    var qs = regex.exec(window.location.href);
    return qs != null;
  }
  
  var _randomString = function() {
    var chars = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXTZabcdefghiklmnopqrstuvwxyz";
    var string_length = 8;
    var randomstring = '';
    for (var i=0; i<string_length; i++) {
      var rnum = Math.floor(Math.random() * chars.length);
      randomstring += chars.substring(rnum,rnum+1);
    }
    return randomstring;
  }

  var _executionId = _randomString(); 

  var _log = function(s, p, i) {
    if(!_isDraft) {
      var theUrl = _logUrl + '?e=' + _executionId + '&s=' + s;
      if(p) {
        theUrl += '&p=' + p;
      }
      if(i) {
        theUrl += '&i=' + i;
      }
      
      _addScript(theUrl);
    }
  }
  
  var LOG_STATUS_EXECUTION_STARTED = 0;
  var LOG_STATUS_PAGE_MATCH = 10;
  var LOG_STATUS_PAGE_NOMATCH = 11;
  var LOG_STATUS_PAGE_NO_FILTERS = 12;
  var LOG_STATUS_INJECTION_OK = 20;
  var LOG_STATUS_INJECTION_FAILED = 21;
  var LOG_STATUS_TAG_NOT_FOUND = 22;
  var LOG_STATUS_LOADER_PARSING_FAILED = 23;
    
  if(!_isDraft && _isDraftRequested()) {
    _addScript(_scriptRequestUrl + '?draft=true');
  } else {
    _log(LOG_STATUS_EXECUTION_STARTED);
    
    var q = {};
    
    q.html = {};
    
    q.html.fileLoader = {};
    
    /**
     * Load a file at url, optionally calling functions before and after it
     * is loaded
     * @param url The url to load
     * @param preLoadAction A function called before the url is loaded. If it
                            returns false or throws an exception it will
                            prevent the url from loading. Takes the url as
                            an argument.
     * @param postLoadHandler A function called after the url is loaded.
     *                        Takes the url as an argument.
     */
    q.html.fileLoader.load = function (url, preLoadAction, postLoadHandler,
        parentNode, async) {
      var scriptEl, preLoadResult, loadError, oldOnError, doPostLoad;
    
      doPostLoad = function () {
        postLoadHandler(url, loadError);
    
        if (oldOnError) {
          window.onerror = oldOnError;
        }
      };
    
      try {
        if (preLoadAction) {
          preLoadResult = preLoadAction(url);
        }
      } catch (e) {
        preLoadResult = false;
      } finally {
        if (preLoadResult !== false) {
          scriptEl = q.html.fileLoader.createScriptEl(url, async);
          if (postLoadHandler) {
            scriptEl.onload = doPostLoad;
            scriptEl.onreadystatechange = function () {
              if ((this.readyState === "complete") ||
                  (this.readyState === "loading")) {
                setTimeout(doPostLoad, 1);
              }
            };
          }
          if (!parentNode) {
            parentNode = window.document.getElementsByTagName("head")[0];
          }
    
          if (window.onerror) {
            oldOnError = window.onerror;
          }
          window.onerror = function (reason, url, lineNumber) {
            loadError = {
              reason: reason,
              url: url,
              lineNumber: lineNumber
            };
            return true;
          };
    
          parentNode.appendChild(scriptEl);
    
        }
      }
    };
    q.html.fileLoader.createScriptEl = function (path, async, forceReload) {
      var scriptEl = document.createElement("script");
      scriptEl.type = "text/javascript";
      scriptEl.src = q.html.fileLoader.tidyUrl(path) +
        (forceReload ? ("?" + new Date().getTime()) : "");
      if (async !== false) {
        scriptEl.async = "true";
        scriptEl.defer = "true";
      } else {
        scriptEl.async = "false";
        if (scriptEl.async !== false) {
          scriptEl.async = false;
        }
        scriptEl.defer = "false";
      }
      return scriptEl;
    };
    
    q.html.fileLoader.tidyUrl = function (path) {
      if (path.substring(0, 5) === 'http:') {
        return path;
      }
      if (path.substring(0, 6) === 'https:') {
        return path;
      }
      return "//" + path;
    };
    /*jslint evil: true */
    /*jslint evil: true */
    
    q.html.GlobalEval = {};
    
    
    q.html.GlobalEval.globalEval = function (src) {
      if (window.execScript) {
        window.execScript(src);
      } else {
        var fn = function () {
          window["eval"].call(window, src);
        };
        fn();
      }
    };
    /*global escape, unescape*/
    
    q.html.HtmlInjector = {};
    
    q.html.HtmlInjector.inject = function (el, injectStart, str, cb, parentNode) {
      var i, ii, d, scriptsRaw, scripts, script, contents;
      if (str.toLowerCase().indexOf("<script") >= 0) {
        d = document.createElement("div");
        d.innerHTML = "a" + str;
        scriptsRaw = d.getElementsByTagName("script");
        scripts = [];
        for (i = 0, ii = scriptsRaw.length; i < ii; i += 1) {
          scripts.push(scriptsRaw[i]);
        }
        contents = [];
        for (i = 0, ii = scripts.length; i < ii; i += 1) {
          script = scripts[i];
          if (script.src) {
            contents.push({src: script.src});
          } else {
            contents.push({script: script.innerHTML});
          }
          script.parentNode.removeChild(script);
        }
        if (d.innerHTML) {
          if (d.innerHTML.length > 0) {
            d.innerHTML = d.innerHTML.substring(1);
          }
        }
        q.html.HtmlInjector.doInject(el, injectStart, d);
        q.html.HtmlInjector.loadScripts(contents, 0, cb, el);
      } else {
        d = document.createElement("div");
        d.innerHTML = str;
        q.html.HtmlInjector.doInject(el, injectStart, d);
        if (cb) {
          cb();
        }
      }
    };

    q.html.HtmlInjector.doInject = function (el, injectStart, d) {
      if (d.childNodes.length > 0) {
        var fragment = document.createDocumentFragment();
        while (d.childNodes.length > 0) {
          fragment.appendChild(d.removeChild(d.childNodes[0]));
        }
        if (injectStart) {
          q.html.HtmlInjector.injectAtStart(el, fragment);
        } else {
          q.html.HtmlInjector.injectAtEnd(el, fragment);
        }
      }
    };
    q.html.HtmlInjector.injectAtStart = function (el, fragment) {
      if (el.childNodes.length === 0) {
        el.appendChild(fragment);
      } else {
        el.insertBefore(fragment, el.childNodes[0]);
      }
    
    };
    q.html.HtmlInjector.injectAtEnd = function (el, fragment, counter) {
      if (!counter) {
        counter = 1;
      }
      if ((el === document.body) &&
          (document.readyState !== "complete") &&
          (counter < 50)) {
        setTimeout(function () {
          q.html.HtmlInjector.injectAtEnd(el, fragment, counter + 1);
        }, 100);
      } else {
        el.appendChild(fragment);
      }
    };
    q.html.HtmlInjector.loadScripts = function (contents, i, cb, parentNode) {
      var ii, c;
      for (ii = contents.length; i < ii; i += 1) {
        c = contents[i];
        if (c.src) {
          q.html.fileLoader.load(
            c.src,
            null,
            function () {
              q.html.HtmlInjector.loadScripts(contents, i + 1, cb, parentNode);
            },
            parentNode
          );
          break;
        } else {
          q.html.GlobalEval.globalEval(c.script);
        }
      }
      if (cb && (i === ii)) {
        cb();
      }
    };

    var urlFilters = [
    <#list pages as page>
    {
        pageId : '${page.id}',
        filterType: "1", //Matches QTag.FILTER_TYPE_INCLUDE/EXCLUDE
        patternType: "3", //Matches QTag.ALL/SUBSTRING/REGEX/EXACT_MATCH
        pattern: "${page.regexp?js_string}", //Pattern for pattern type.
        priority: 1,
       	scriptLoaderKeys: [
       	<#list page.injections as injection>
       	'${injection.id}',
       	</#list>
       	] 
    },
    </#list>
    ],
      scriptLoaders = {
      <#list pages as page>
      <#list page.injections as injection>
      	'${injection.id}' : {
          id: "${injection.id}",
      	  pageId : '${page.id}',
          name: "",
          pre: "", 
          url: "", 
          post: "", 
          html: "${injection.html}",
          locationId: ${injection.location.id},
          positionId: ${injection.position.id},
          locationDetail: "${injection.divId}", 
          async: "", 
          usesDocWrite: false,
      	},
      </#list>
      </#list>
      };

    function QTag(urlFilters, scriptLoaders) {
      QTag.qTagLoaders = QTag.getLoaders(urlFilters, scriptLoaders, document.URL);
      QTag.loadersFinished = 0;
      QTag.loadLoaders();
    }
    
    QTag.ALL = "1";
    QTag.SUBSTRING = "2";
    QTag.REGEX = "3";
    QTag.EXACT_MATCH = "4";
    
    QTag.FILTER_TYPE_INCLUDE = "1";
    QTag.FILTER_TYPE_EXCLUDE = "2";
    
    /**
     * @param urlFilter An array containing objects which have a pattern type and
     *   a filter type
     */
    QTag.getLoaders = function (urlFilters, scriptLoaders, url) {
      var i, ii, urlFilter, loaderKeysSet = {}, matchedFilters = [],
        loaders = [];
    
      if ((!urlFilters) || (!url)) {
        _log(LOG_STATUS_PAGE_NO_FILTERS);
        return loaders;
      }
      for (i = 0, ii = urlFilters.length; i < ii; i += 1) {
        urlFilter = urlFilters[i];
        if (!!urlFilter && QTag.doesUrlFilterMatch(urlFilter, url)) {
          matchedFilters.push(urlFilter);
          _log(LOG_STATUS_PAGE_MATCH, urlFilter.pageId);
        }
      }
      if(matchedFilters.length === 0){
        _log(LOG_STATUS_PAGE_NOMATCH);
      }
      matchedFilters.sort(function (a, b) {
        return b.priority - a.priority;
      });
      for (i = 0, ii = matchedFilters.length; i < ii; i += 1) {
        QTag.updateLoaders(matchedFilters[i], loaderKeysSet);
      }
      for (i in loaderKeysSet) {
        if (loaderKeysSet.hasOwnProperty(i)) {
          loaders.push(scriptLoaders[i]);
        }
      }
      return loaders;
    };
      /**
       * Checks to see if a url filter matches a url
       */
    QTag.doesUrlFilterMatch = function (urlFilter, url) {
      var matches = false;
      switch (urlFilter.patternType) {
      case QTag.EXACT_MATCH:
        if (url.toLowerCase() === urlFilter.pattern.toLowerCase()) {
          matches = true;
        }
        break;
      case QTag.SUBSTRING:
        if (url.toLowerCase().indexOf(urlFilter.pattern.toLowerCase()) >= 0) {
          matches = true;
        }
        break;
      case QTag.REGEX:
        if (new RegExp(urlFilter.pattern).test(url)) {
          matches = true;
        }
        break;
      case QTag.ALL:
        matches = true;
        break;
      }
      return matches;
    };
    /**
     * Update the loader key set with the given filter
     */
    QTag.updateLoaders = function (urlFilter, loaderKeysSet) {
      var i, ii, scriptLoaderKeys = urlFilter.scriptLoaderKeys;
      if (urlFilter.filterType === QTag.FILTER_TYPE_INCLUDE) {
        for (i = 0, ii = scriptLoaderKeys.length; i < ii; i += 1) {
          if (scriptLoaderKeys.hasOwnProperty(i)) {
            loaderKeysSet[scriptLoaderKeys[i]] = true;
          }
        }
      } else if (urlFilter.filterType === QTag.FILTER_TYPE_EXCLUDE) {
        for (i = 0, ii = scriptLoaderKeys.length; i < ii; i += 1) {
          if (scriptLoaderKeys.hasOwnProperty(i)) {
            delete loaderKeysSet[scriptLoaderKeys[i]];
          }
        }
      }
    };
    
    QTag.waitCounts = {};
    QTag.maxLoads = 10;
    QTag.loadCheckInterval = 500;
    
    QTag.loadLoaders = function () {
      var i, ii, qTagLoader, err;
      QTag.docWriteUsers = [];
    
      for (i = 0, ii = QTag.qTagLoaders.length; i < ii; i += 1) {
        qTagLoader = QTag.qTagLoaders[i];
        try {
          if (qTagLoader.usesDocWrite) {
            QTag.docWriteUsers.push(qTagLoader);
          } else {
            QTag.doWhenReady(qTagLoader, QTag.loadTagLoader, function (failedLoader) {
              _log(LOG_STATUS_TAG_NOT_FOUND, failedLoader.pageId, failedLoader.id);
            });
          }
        } catch (e) {
          _log(LOG_STATUS_LOADER_PARSING_FAILED, qTagLoader.pageId, qTagLoader.id);
          
          err = {
            reason: "error parsing loader, " + qTagLoader.id + ": " + e.reason,
            url: document.location.href
          };
          if (window.debug) {
            console.log(err);
          }
        }
      }
      QTag.loadLoadersSequentially();
    };
    
    QTag.doWhenReady = function (qTagLoader, f, timeoutHandler) {
      QTag.waitCounts[qTagLoader.id] = 0;
      QTag._doWhenReady(qTagLoader, f, timeoutHandler);
    };
    QTag._doWhenReady = function (qTagLoader, f, timeoutHandler) {
      if (QTag.canLoad(qTagLoader)) {
        f(qTagLoader);
      } else {
        if (QTag.waitCounts[qTagLoader.id] < QTag.maxLoads) {
          QTag.waitCounts[qTagLoader.id] += 1;
          setTimeout(function () {
            QTag._doWhenReady(qTagLoader, f, timeoutHandler);
          }, QTag.loadCheckInterval);
        } else {
          timeoutHandler(qTagLoader);
        }
      }
    };
    QTag.canLoad = function (qTagLoader) {
      if (qTagLoader.locationId === 2) {
        return !!document.body;
      } else if (qTagLoader.locationId === 3) {
        return !!document.getElementById(qTagLoader.locationDetail);
      }
      return true;
    };
    QTag.loadLoadersSequentially = function () {
      var qTagLoader, finishHandler;
      if (QTag.docWriteUsers.length > 0) {
        qTagLoader = QTag.docWriteUsers[0];
        QTag.docWriteUsers.shift();
        QTag.doWhenReady(qTagLoader, QTag.loadLoaderSequentially, function () {
          QTag.loadLoadersSequentially();
        });
      }
    };
    QTag.loadLoaderSequentially = function (qTagLoader) {
      var text = [];
      document.write = function (t) {
        text.push(t);
      };
      document.writeln = function (t) {
        text.push(t);
      };
      finishHandler = function () {
        var el = QTag.getLocation(qTagLoader);
        q.html.HtmlInjector.inject(el, qTagLoader.positionId === 1,
            text.join("\n"), QTag.loadLoadersSequentially);
      };
      qTagLoader.finishHandler = finishHandler;
      QTag.loadTagLoader(qTagLoader);
    };
    QTag.loadTagLoader = function (qTagLoader) {
      var ender = QTag.getTimerEnder(qTagLoader);
      try {
        if (qTagLoader.url) {
          q.html.fileLoader.load(
            qTagLoader.url,
            QTag.getTimerStarter(qTagLoader),
            ender,
            qTagLoader.parentNode,
            qTagLoader.async
          );
        } else if (qTagLoader.html) {
          QTag.injectHtml(qTagLoader);
          _log(LOG_STATUS_INJECTION_OK, qTagLoader.pageId, qTagLoader.id);
        }
      } catch (e) {
        _log(LOG_STATUS_INJECTION_FAILED, qTagLoader.pageId, qTagLoader.id);
        ender(null, e);
      }
    };
    QTag.injectHtml = function (qTagLoader) {
      var el = QTag.getLocation(qTagLoader);
      QTag.getTimerStarter(qTagLoader)();
      q.html.HtmlInjector.inject(el, qTagLoader.positionId === 1,
          qTagLoader.html, QTag.getTimerEnder(qTagLoader));
    };
    QTag.getLocation = function (qTagLoader) {
      var el;
      if (qTagLoader.locationId === 1) {
        el = document.getElementsByTagName("head")[0];
      } else if (qTagLoader.locationId === 2) {
        el = document.body;
      } else if (qTagLoader.locationId === 3) {
        el = document.getElementById(qTagLoader.locationDetail);
      } else {
        el = document.body;
      }
      return el;
    };

    QTag.getTimerStarter = function (qTagLoader) {
      return QTag.createStatementEvaluator(qTagLoader.pre);
    };
    QTag.getTimerEnder = function (qTagLoader) {
      return function (url, error) {
        if (qTagLoader.finishHandler) {
          qTagLoader.finishHandler();
        }
        return QTag.createStatementEvaluator(qTagLoader.post)();
      };
    };

    QTag.createStatementEvaluator = function (statement) {
      if ((!!statement) && (statement.length > 0)) {
        var fn, toRun = 'fn = function() {\n' +
          'q.html.GlobalEval.globalEval(statement);\n' +
          'QTag.incrementLoadCounter([]);\n' +
          '};';
        eval(toRun);
        return fn;
      } else {
        return function () {
          QTag.incrementLoadCounter([]);
        };
      }
    };

    QTag.incrementLoadCounter = function () {
      QTag.loadersFinished += 1;
      if (QTag.loadersFinished === QTag.qTagLoaders.length * 2) {
        if (window.qTag_allLoaded) {
          window.qTag_allLoaded();
        }
      }
    };
  	
    return new QTag(urlFilters || [], scriptLoaders || {});
  }
}());
