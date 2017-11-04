#!/usr/bin/env phantomjs
var system = require('system');
var filename = system.args[1];
var url = 'file://' + system.env.PWD + '/' + filename;

var page = require('webpage').create();

page.onResourceError = function(resourceError) {
  console.log('ResourceError: ' + resourceError.url);
}

console.log('Loading: ' + url);
page.open(url, function(status) {
  console.log('Loaded: ' + url + '(' + status + ')');
  var slides = page.evaluate(function() {
    return document.getElementsByClassName('remark-slide-container');
  });
  console.log('Number of slides: ' + slides.length);
  console.log('Done: ' + url + '(' + status + ')');
  phantom.exit();
});
