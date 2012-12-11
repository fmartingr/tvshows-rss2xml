// Generated by CoffeeScript 1.3.3
var DDBB, DEBUG, HOSTS, app, createHash, crypto, env, express, generateMongoUrl, getParser, loadParser, mongo, mongodb, mongoose, parsers, rss, rssSchema, url;

express = require('express');

url = require('url');

crypto = require('crypto');

mongoose = require('mongoose');

app = express();

parsers = require("./parsers");

HOSTS = require('./hosts');

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

DDBB = {
  collection: 'rss',
  connection: generateMongoUrl(mongo)
};

mongodb = mongoose.createConnection(DDBB.connection);

mongodb.on('error', console.error.bind(console, 'connection error: '));

rssSchema = new mongoose.Schema({
  hash: {
    type: String,
    index: true
  },
  parser: {
    type: String,
    "default": 'default'
  },
  url: String,
  added: {
    type: Date,
    "default": Date.now
  }
}, {
  collection: 'rss'
});

getParser = function(_url) {
  var host, parser;
  parser = 'default';
  host = url.parse(_url).host.replace("/", "").replace("www.", "");
  if (HOSTS[host] != null) {
    parser = HOSTS[host];
  }
  return parser;
};

createHash = function(_url, _parser) {
  var hash;
  hash = crypto.createHash('md5');
  return hash.update(_url + _parser).digest('hex');
};

rss = mongodb.model('rss', rssSchema);

loadParser = function(_parser) {
  if (parsers[_parser]) {
    return new parsers[parserType]();
  } else {
    return null;
  }
};

app.use(express.bodyParser());

app.get("/", function(request, response) {
  return response.sendfile("public/home.html");
});

app.use("/static", express["static"](__dirname + '/public/static'));

app.post("/", function(request, response) {
  var hash, parser, rssUrl;
  rssUrl = request.param('rss');
  parser = getParser(rssUrl);
  hash = createHash(rssUrl, parser);
  return rss.findOne({
    hash: hash
  }, function(_error, _item) {
    var item;
    if (_item !== null) {
      item = _item;
    } else {
      item = new rss({
        url: rssUrl,
        hash: hash,
        parser: parser
      });
      item.save();
    }
    response.redirect("/" + item.hash + ".xml");
    return response.end();
  });
});

app.get("/:rss.xml", function(request, response) {
  response.send('load parser here!');
  return response.end();
});

app.listen(process.env.VCAP_APP_PORT || 3000);
