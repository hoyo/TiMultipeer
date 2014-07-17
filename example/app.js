TiMC = require('com.hoyosta.timultipeer');

session = TiMC.createSession();
session.advertize();
//or
//session.browse();

session.addEventListener('connect', function(e) {
  Ti.API.info('** connected **');
  session.sendData("test");
});

session.addEventListener('disconnect', function(e) {
  Ti.API.info('** disconnected **');
});

session.addEventListener('receive', function(e) {
  Ti.API.info('** received ** : ' + e.data);
});
