#!/usr/bin/env phantomjs
var system = require('system');
var filename = system.args[1];
var url = 'file://' + system.env.PWD + '/' + filename;

var page = require('webpage').create();

page.onResourceError = function(resourceError) {
  console.log('ResourceError: ' + resourceError.url);
}

page.onConsoleMessage = function(msg) {
  console.log('Console: ' +msg);
}

console.log('Loading: ' + url);
page.open(url, function(status) {
  console.log('Loaded: ' + url + '(' + status + ')');

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
    ret.titles = {};
    ret.slides = {};
    ret.n_slides = n;
    for (i=1; i<=n; i++) {
      console.log('Current slide: ' + i + '/' + n);
      var visible_slide = document.getElementsByClassName('remark-visible')[0];
      ['h1', 'h2'].forEach(function(tag) {
        var titles = visible_slide.getElementsByTagName(tag);
        console.log('Found ' + titles.length + ' titles with tag ' + tag);
        titles.forEach(function(t) {
          if (t.clientHeight>60) {
            ret.titles[t.textContent] = i;
          }
        });
      });
      var scaler = visible_slide.getElementsByClassName('remark-slide-scaler')[0];
      var slide = scaler.getElementsByClassName('remark-slide')[0];
      if (slide.clientHeight > scaler.clientHeight) {
        ret.slides[slide.textContent] = i;
      }
      slideshow.gotoNextSlide();
    }
    return ret;
  });
  Object.keys(analyze.titles).forEach(function(t) {
    console.log('Title overflow on slide ' + analyze.titles[t] +': ' + t);
  });
  Object.keys(analyze.slides).forEach(function(s) {
    console.log('Slide overflow: ' + analyze.slides[s]);
  })
  console.log('Number of slides: ' + analyze.n_slides);

  console.log('Done: ' + url + '(' + status + ')');
  phantom.exit();
});
