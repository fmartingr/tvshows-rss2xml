// Generated by CoffeeScript 1.3.3
var DEBUG, app, crypto, env, express, generateMongoUrl, hosts, loadParser, mongo, mongourl, parsers, rss, url;

express = require('express');

url = require('url');

crypto = require('crypto');

app = express();

parsers = require("./parsers");

hosts = require('./hosts');

DEBUG = true;

if (process.env.VCAP_SERVICES) {
  env = JSON.parse(process.env.VCAP_SERVICES);
  mongo = env['mongodb-1.8'][0]['credentials'];
} else {
  mongo = {
    "hostname": "localhost",
    "port": 27017,
    "username": "",
    "password": "",
    "name": "",
    "db": "db"
  };
}

generateMongoUrl = function(_object) {
  _object.hostname = _object.hostname || 'localhost';
  _object.port = _object.port || 27017;
  _object.db = _object.db || 'test';
  if (_object.username && _object.password) {
    return "mongodb://" + _object.username + ":" + _object.password + "@" + _object.hostname + ":" + _object.port + "/" + _object.db;
  } else {
    return "mongodb://" + _object.hostname + ":" + _object.port + "/" + _object.db;
  }
};

mongourl = generateMongoUrl(mongo);

rss = (function() {

  function rss(url, parser) {
    this.url = url;
    this.parser = parser != null ? parser : "default";
    if (url) {
      this.getParser();
      this.createHash();
    }
  }

  rss.prototype.getParser = function() {
    var host;
    host = url.parse(this.url).pathname.replace("/", "").replace("www.", "");
    if (hosts[host] != null) {
      return this.parser = hosts[host];
    }
  };

  rss.prototype.getFromId = function(_id) {};

  rss.prototype.createHash = function() {
    var hash;
    if (this.url && this.parser) {
      hash = crypto.createHash('md5');
      return this.hash = hash.update(this.url + this.parser).digest('hex');
    }
  };

  rss.prototype.save = function() {};

  return rss;

})();

loadParser = function(_parser) {
  if (parsers[_parser]) {
    return new parsers[parserType]();
  } else {
    return null;
  }
};

app.use(express.bodyParser());

app.get("/", function(request, response) {
  return response.sendfile("html/home.html");
});

app.post("/", function(request, response) {
  var item, rssUrl;
  rssUrl = request.param('rss');
  item = new rss(rssUrl);
  item.save();
  response.redirect("/" + item.hash + ".xml");
  return response.end();
});

app.get("/:rss.xml", function(request, response) {
  response.send('load parser here!');
  return response.end();
});

app.listen(process.env.VCAP_APP_PORT || 3000);
