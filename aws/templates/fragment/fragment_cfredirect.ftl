[#case "cfredirect"]
[#case "_cfredirect"]

    [@DefaultLinkVariables enabled=false /]
    [@DefaultCoreVariables enabled=false /]
    [@DefaultEnvironmentVariables enabled=false /]

    [#assign redirectScript = [
        "'use strict';",
        "/* This function is used to perform redirects when an application has moved domains", 
        "    Any request that does not have a host header which matches the Primary Domain",
        "    will be redirected to the same location with the new domain name */",
        "exports.handler = (event, context, callback) => {",
        "    const request = event.Records[0].cf.request;",
        "    const headers = request.headers;",
        "    const host = headers.host[0].value.toLowerCase();",
        "    if ( request.origin.custom ) {",
        "        var customHeaders = request.origin.custom.customHeaders;",
        "    }",
        "    if ( request.origin.s3 ) { ",
        "        var customHeaders = request.origin.s3.customHeaders;",
        "    }",
        "    const redirectPrimaryDomainHeaderName = 'X-Redirect-Primary-Domain-Name';",
        "    const redirectResponseCodeHeaderName = 'X-Redirect-Response-Code';",
        "    if ( customHeaders[redirectPrimaryDomainHeaderName.toLowerCase()]) {",
        "        var primaryHost = (customHeaders[redirectPrimaryDomainHeaderName.toLowerCase()][0]).value;",
        "    } else {",
        "        var primaryHost = host;",
        "    }",
        "    if ( customHeaders[redirectResponseCodeHeaderName.toLowerCase()]) {",
        "        var redirectCode = (customHeaders[redirectResponseCodeHeaderName.toLowerCase()][0]).value;",
        "    } else {",
        "        var redirectCode = '302';",
        "    }",
        "    /* If for primary domain, proceed with request */",
        "    if ( host === primaryHost  ) {",
        "        callback(null, request);",
        "    } else {",
        "        var redirectUrl = 'https://' + primaryHost;",
        "        if (request.uri != '/') {",
        "        redirectUrl = redirectUrl + request.uri;",
        "        }",
        "        if (request.querystring != '') {",
        "        redirectUrl = redirectUrl + '?' + request.querystring;",
        "        }",
        "        /* Send the redirect */",
        "        const response = {",
        "            status: redirectCode,",
        "            statusDescription: 'Relocated',",
        "            headers: {",
        "                location: [{",
        "                    key: 'Location',",
        "                    value: redirectUrl,",
        "                }],",
        "            },",
        "        };",
        "        callback(null, response);",
        "    }",
        "};"
            ]]

    [@lambdaAttributes 
        zipFile=redirectScript 
    /]
    
    [#-- Ensure Environment Variables are empty for lambda@Edge --]
    [#assign _context += {
        "DefaultEnvironment" : {},
        "Environment" : {}
    }]
    [#break]