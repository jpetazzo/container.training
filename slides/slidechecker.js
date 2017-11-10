#!/usr/bin/env phantomjs
var system = require('system');
var filename = system.args[1];
var url = 'file://' + system.env.PWD + '/' + filename;

var page = require('webpage').create();

page.onResourceError = function(resourceError) {
  console.log('ResourceError: ' + resourceError.url);
}

page.onConsoleMessage = function(msg) {
  //console.log('Console: ' +msg);
}

console.log('DEBUG Loading: ' + url);
page.open(url, function(status) {
  console.log('DEBUG Loaded: ' + url + '(' + status + ')');

  /* analyze will be an object with:
   *
   * titles
   * A dict with all the titles that are too high
   * (i.e. because they have been broken across multiple
   * lines because they are too long)
   *
   * slides
   * A dict with the slides that are too high
   *
   * n_slides
   * Number of slides found
   */
  var analyze = page.evaluate(function() {
    var ret = {}, i, n = slideshow.getSlideCount();
    ret = [];
    for (i=1; i<=n; i++) {
      console.log('DEBUG Current slide: ' + i + '/' + n);
      var visible_slide = document.getElementsByClassName('remark-visible')[0];
      var debug = visible_slide.getElementsByClassName('debug');
      if (debug.length==0) {
        debug = '?';
      }
      else {
        debug = debug[0].textContent;
      }
      var slide_desc = 'Slide ' + i + '/' + n + ' (' + debug + ')';
      ['h1', 'h2'].forEach(function(tag) {
        var titles = visible_slide.getElementsByTagName(tag);
        console.log('DEBUG Found ' + titles.length + ' titles with tag ' + tag);
        titles.forEach(function(t) {
          if (t.clientHeight>60) {
            ret.push(slide_desc + ' has a long title: ' + t.textContent);
          }
        });
      });
      var scaler = visible_slide.getElementsByClassName('remark-slide-scaler')[0];
      var slide = scaler.getElementsByClassName('remark-slide')[0];
      if (slide.clientHeight > scaler.clientHeight) {
        ret.push(slide_desc + ' is too long');
      }
      slideshow.gotoNextSlide();
    }
    ret.push('Deck has ' + n + ' slides');
    return ret;
  });
  analyze.forEach(function(msg) {
    console.log(msg);
  });
  console.log('DEBUG Done: ' + url + '(' + status + ')');
  phantom.exit();
});
