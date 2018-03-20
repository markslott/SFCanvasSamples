<%@ page import="canvas.SignedRequest" %>
<%@ page import="java.util.Map" %>
<%
    // Pull the signed request out of the request body and verify/decode it.
    Map<String, String[]> parameters = request.getParameterMap();
    String[] signedRequest = parameters.get("signed_request");
    if (signedRequest == null) {%>
        This App must be invoked via a signed request!<%
        return;
    }
    String yourConsumerSecret=System.getenv("CANVAS_CONSUMER_SECRET");
    //String yourConsumerSecret="1818663124211010887";
    String signedRequestJson = SignedRequest.verifyAndDecodeAsJson(signedRequest[0], yourConsumerSecret);
%>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" lang="en">
<head>

    <title>Hello World Canvas Example</title>

    <link rel="stylesheet" type="text/css" href="/sdk/css/canvas.css" />

    <!-- Include all the canvas JS dependencies in one file -->
    <script type="text/javascript" src="/sdk/js/canvas-all.js"></script>
    <!-- Third part libraries, substitute with your own -->
    <script type="text/javascript" src="/scripts/json2.js"></script>
    <script
        src="https://code.jquery.com/jquery-2.2.4.min.js"
        integrity="sha256-BbhdlvQf/xTY9gja0Dq3HiwQF8LaCRTXxZKRutelT44="
        crossorigin="anonymous"></script>
    <script>
        if (self === top) {
            // Not in Iframe
            alert("This canvas app must be included within an iframe");
        }

        var sr;
        var caseId;


       Sfdc.canvas(function () {

            console.log('canvas app document ready.');

            
            sr = JSON.parse('<%=signedRequestJson%>');
            Sfdc.canvas.oauth.token(sr.oauthToken);
            Sfdc.canvas.byId('signedrequestjson').innerHTML = JSON.stringify(sr, undefined, 2);
            Sfdc.canvas.client.subscribe(sr.client,
                {name : 'mynamespace.caseIdChanged', onData : function (event) {
                    console.log("Subscribed to custom event ", event);
                    Sfdc.canvas.byId('caseId').innerHTML = event.caseId;
                    caseId = event.caseId;
                }}
            );
            
            $("#updateCaseButton").click(function(){
                var url = "/services/data/v41.0/sobjects/Case/" + caseId;
                console.log("url: " + url);
                var description = $("#value1").text();
                var caseData = { description : description };
                console.log("caseData = " + JSON.stringify(caseData));
                Sfdc.canvas.client.ajax(url,
                    {client : sr.client,
                        method: 'PATCH',
                        data: JSON.stringify(caseData),
                        contentType: "application/json",
                        success : function(data) {
                            console.log(data);
                            //send a message back to the parent frame telling it update occured
                            //you'd check the status code here and act accordingly
                            
                            Sfdc.canvas.client.publish(sr.client,
                                    {name : "mynamespace.caseUpdated", payload : {}});
                        }
                    }
                );
            });

            Sfdc.canvas.client.publish(sr.client,
                {name : "mynamespace.caseRequested", payload : {caseId : null}});
        });

    </script>
</head>
<body>
    <h1>Sample Canvas Case Update App</h1><br/>
    <h2>Enter a description to add to case record <span id="caseId"></span>: </h2><br/>
    <input id="value1" type="text"/>
    <button id="updateCaseButton" style="width: 100px;background: lightblue">Update Case</button>
    <br/>
    <h2>Signed Request Token deserialized</h2>
    <br/>
    <div style="overflow-y: scroll; height: 300px; width:100%">
        <pre>
        <span id='signedrequestjson'></span>
        </pre>
    </div>
</body>
</html>
