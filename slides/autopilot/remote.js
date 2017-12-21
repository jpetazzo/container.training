/* This snippet is loaded from the workshop HTML file.
 * It sets up callbacks to synchronize the local slide
 * number with the remote pub/sub server.
 */

var socket = io();
var leader = true;

slideshow.on('showSlide', function (slide) {
  if (leader) {
    var n = slide.getSlideIndex()+1;
    socket.emit('slide change', n);
  }
});

socket.on('slide change', function (n) {
  leader = false;
  slideshow.gotoSlide(n);
  leader = true;
});

