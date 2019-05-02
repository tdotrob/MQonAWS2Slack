//-----------------------------------------------------------------------
// aws2slack.js
// 
// Post messages from IBM MQ running in AWS to Slack
// 
// Receives publication from SNS, formats to Slack message attachment
// and posts to Slack webhook URL.
// 
// Function handles Slack basic message fields plus all message
// attachment fields. Each SNS publication is fornatted to a single
// Slack message plus one attachment. This is planty of room for any
// individual MQ event or error messages, an MQ Config report, or most
// othr MQ-related alerts.
// 
// Tested in Lambda using NodeJS 8.10
// 
//----------------------------------------------------------------------

var https = require('https');
var util = require('util');

exports.handler = function(event, context) {
	console.log(JSON.stringify(event, null, 2));

	var postData = {
	  "channel": process.env.SlackChl,
	  "username": process.env.SlackUser,
	  "text": "*" + event.Records[0].Sns.Subject + "*",
	  "icon_emoji": ":mailbox_with_mail:"
	};

	function Attach() {
	  var Template= {
		  "fallback": "Fallback",
		  "color": "#cccccc",
		  "pretext": "Pretext",
		  "author_name": "MQ-to-Slack",
		  "author_link": "http://github.com/tdotrob/",
		  "title": "Title",
		  "text": event.Records[0].Sns.Message + "\n",
		  "footer": "MQ-to-slack",
		  "ts": Date.now() / 1000
		};
		
	  for(var propt in event.Records[0].Sns.MessageAttributes){
		var ipropt=propt.toUpperCase();
		//console.log("\nAttribute="+propt+"="+event.Records[0].Sns.MessageAttributes[propt].Value);
		switch (ipropt) {
		  case "CHROME":
			//console.log("Chrome="+event.Records[0].Sns.MessageAttributes[propt].Value);
			var i, field = event.Records[0].Sns.MessageAttributes[propt].Value.split(",");
			for (i = 0; i < field.length; i++) {
			  var kv=field[i].split(":");
			  var iKey=kv[0].toUpperCase();
			  switch (iKey){
				case "EMOJI":
				  postData.icon_emoji=':'+kv[1]+':';
				  //console.log("Emoji="+kv[1]);
				  break;
				case "COLOR":
				  Template.color=kv[1];
				  //console.log("Color="+kv[1]+"\n");
				  break;
				case "USERNAME":
				  postData.username=kv[1];
				  //console.log("Username="+kv[1]+"\n");
				  break;
			  }
			}
			break;
		  case "PRETEXT":     
			Template.pretext=event.Records[0].Sns.MessageAttributes[propt].Value;
			//console.log("PRETEXT="+Template.pretext);
			break;
		  case "KVPAIRS":
			Template.text+=event.Records[0].Sns.MessageAttributes[propt].Value.replace(/,/g,"\n");
			//console.log("KVPAIRS="+Template.text);
			break;
		}
	  }
	  return Template;
	}

	postData.attachments = [ Attach() ];
	console.log(JSON.stringify(postData, null, 2));

    var options = {
        method: 'POST',
        hostname: 'hooks.slack.com',
        port: 443,
        path: process.env.SlackURL
    };

    var req = https.request(options, function(res) {
      res.setEncoding('utf8');
      res.on('data', function (chunk) {
        context.done(null);
      });
    });
    
    req.on('error', function(e) {
      console.log('problem with request: ' + e.message);
    });    

    req.write(util.format("%j", postData));
    req.end();
    console.log(JSON.stringify(postData, null, 2));
};
