// A system package containing protocol access constructs
// Package objects referenced with 'http:' in code
import ballerina/http;
import ballerina/io;
import wso2/twitter;
import ballerina/config;
import ballerina/log;

endpoint twitter:Client twitter {
   clientId: config:getAsString("consumerKey"),
   clientSecret: config:getAsString("consumerSecret"),
   accessToken: config:getAsString("accessToken"),
   accessTokenSecret: config:getAsString("accessTokenSecret")
};


documentation {
   A service endpoint represents a listener.
}
endpoint http:Listener listener {
    port:8080
};

documentation {
   A service is a network-accessible API
   Advertised on '/hello', port comes from listener endpoint
}

 @http:ServiceConfig {
   basePath: "/"
}
service<http:Service> hello bind listener {

    @http:ResourceConfig {
        methods: ["POST"],
        path: "/twitter"
    }

    documentation {
       A resource is an invokable API method
       Accessible at '/hello/sayHello
       'caller' is the client invoking this resource 

       P{{caller}} Server Connector
       P{{request}} Request

       
    }

    
    sayHello (endpoint caller, http:Request request) {
        // get the req from the database service
        json req = check request.getJsonPayload();

        //this is to extract the values from the request
        string name = req.name.toString();
        string oldJob = req.old.toString();
        string newJob = req.newJ.toString();
        //create the message to be tweeted
        string tweetMessage = name + " has been promoted as " + newJob + " from " + oldJob;
        
        //to send the tweet
       twitter:Status st = check twitter->tweet(tweetMessage, "", "");

       //after executing the tweet send a response back to the databse service as a json file
        http:Response response = new;
        json payload = { old: oldJob, newJ: newJob, name: name};
        response.setJsonPayload(payload);
        // caller is the one from where the request was sent therefore it is sending the response back to it.
        _ = caller -> respond(response);
    }
}