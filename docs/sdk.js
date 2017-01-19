(function (window) {

  'use strict';

     function injectScript(src, cb) {
       var sj = document.createElement('script');
       sj.type = 'text/javascript';
       sj.async = true;
       sj.src = src;
       sj.addEventListener ? sj.addEventListener('load', cb, false) : sj.attachEvent('onload', cb);
       var s = document.getElementsByTagName('script')[0];
       s.parentNode.insertBefore(sj, s);
     }


    // declare
    var pwd = function () {
        this.instances = {};
        this.instanceBuffer = {};
        return;
    };

    var verifyCallback = function(response) {
      var self = this;
      var data = encodeURIComponent('g-recaptcha-response') + '=' + encodeURIComponent(response);
      postRequest(this.baseUrl + '/', {headers:{'Content-type':'application/x-www-form-urlencoded'}}, data, function(resp) {

        //TODO handle errors
        if (resp.status == 200) {
          self.init(resp.responseText, self.opts);
          self.selectors.forEach(function(sel){
            self.terminal(sel, function() {
              //Remove captchas after initializing terminals;
              var captcha = document.querySelectorAll(sel + ' .captcha');
              captcha.forEach(function(el){
                el.parentNode.removeChild(el);
              });
            });
          });
        };
      });
    };

    // register recaptcha onload callback only once
    window.onloadCallback = function() {
      var sel = window.pwd.selectors[0];
      var els = document.querySelectorAll(sel);
      els.forEach(function(el) {
        var captcha = document.createElement('div');
        captcha.className = 'captcha';
        el.appendChild(captcha);
        window.grecaptcha.render(captcha, {'sitekey': '6Ld8pREUAAAAAOkrGItiEeczO9Tfi99sIHoMvFA_', 'callback': verifyCallback.bind(window.pwd)});
      });
    };

    pwd.prototype.newSession = function(selectors, opts) {
      this.opts = opts || {};
      this.baseUrl = this.opts.baseUrl || 'http://play-with-docker.com';
      selectors = selectors || [];
      if (selectors.length > 0) {
        this.selectors = selectors;
        injectScript('https://www.google.com/recaptcha/api.js?onload=onloadCallback&render=explicit');
      } else {
        console.warn('No DOM elements found for selectors', selectors);
      }
    };

    // your sdk init function
    pwd.prototype.init = function (sessionId, opts) {
      var self = this;
      opts = opts || {};
      this.baseUrl = opts.baseUrl || 'http://play-with-docker.com';
      this.sessionId = sessionId;
      this.socket = io(this.baseUrl, {path: '/sessions/' + sessionId + '/ws' });
      this.socket.on('terminal out', function(name ,data) {
        var instance = self.instances[name];
        if (instance && instance.terms) {
          instance.terms.forEach(function(term) {term.write(data)});
        } else {
          //Buffer the data if term is not ready
          if (self.instanceBuffer[name] == undefined) self.instanceBuffer[name] = '';;;;
          self.instanceBuffer[name] += data;
        }
      });

      // Resize all terminals
      this.socket.on('viewport resize', function(cols, rows) {
        // Resize all terminals
        for (var name in self.instances) {
          self.instances[name].terms.forEach(function(term){
            term.resize(cols,rows);
          });
        };
      });

      // Handle window resizing
      window.onresize = function() {
        self.resize();
      };
    };


    pwd.prototype.resize = function() {
      var name = Object.keys(this.instances)[0]
      if (name) {
        var size = this.instances[name].terms[0].proposeGeometry();
        this.socket.emit('viewport resize', size.cols, size.rows);
      }
    };

    // I know, opts and data can be ommited. I'm not a JS developer =(
    // Data needs to be sent encoded appropriately
    function postRequest(url,opts, data, callback) {
      var request = new XMLHttpRequest();
      request.open('POST', url, true);

      if (opts && opts.headers) {
        for (var key in opts.headers) {
          request.setRequestHeader(key, opts.headers[key]);
        }
      }
      request.setRequestHeader('X-Requested-With', 'XMLHttpRequest')
      request.onload = function() {
        callback(request);
      };
      request.send(data);
    };

    pwd.prototype.createInstance = function(callback) {
      var self = this;
      //TODO handle http connection errors
      postRequest(self.baseUrl + '/sessions/' + this.sessionId + '/instances', undefined, undefined, function(response) {
        if (response.status == 200) {
          var i = JSON.parse(response.responseText);
          i.terms = [];
          self.instances[i.name] = i;
          callback(undefined, i);
        } else if (response.status == 409) {
          var err = new Error();
          err.max = true;
          callback(err);
        } else {
          callback(new Error());
        }
      });
    }

    pwd.prototype.createTerminal = function(selector, name) {
        var self = this;
        var i = this.instances[name];
        // Create terminal might be called independently
        // That's why we need to lazy-load the term in memory if it doesn't exist
        if (!i) {
          i = {name: name, terms: []};
          this.instances[name] = i;
        }


        var elements = document.querySelectorAll(selector);
        elements.forEach(function(el) {
          var term = new Terminal({cursorBlink: false});
          term.open(el);
          term.on('data', function(d) {
            self.socket.emit('terminal in', i.name, d);
          });
          var size = term.proposeGeometry();
          self.socket.emit('viewport resize', size.cols, size.rows);
          i.terms.push(term);
        });



        // Attach block actions
        var actions = document.querySelectorAll('code[class*="'+selector+'"]');
        actions.forEach(function(actionEl) {
          actionEl.onclick = function() {
            self.socket.emit('terminal in', i.name, this.innerText);
          };
        });


        if (self.instanceBuffer[name]) {
          //Flush buffer and clear it
          i.terms.forEach(function(term){
            term.write(self.instanceBuffer[name]);
          });
          self.instanceBuffer[name] = '';
        }

        return i.terms;
    }

    pwd.prototype.terminal = function(selector, callback) {
      var self = this;
      this.createInstance(function(err, instance) {
          if (err && err.max) {
            !callback || callback(new Error("Max instances reached"))
            return
          } else if (err) {
            !callback || callback(new Error("Error creating instance"))
            return
          }

          self.createTerminal(selector, instance.name);


          !callback || callback(undefined, instance);

      });
    }



    // define your namespace myApp
    window.pwd = new pwd();

})(window, undefined);
