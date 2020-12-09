[#ftl]

[@addExtension
    id="cfredirect"
    aliases=[
        "_cfredirect-v1"
    ]
    description=[
        "AWS Lambda@Edge function used to send 301 redirections from any domains which are not the primary domain",
        "The header - X-Redirect-Primary-Domain-Name defines the primary domain name where requests should be redirected"
    ]
    supportedTypes=[
        LAMBDA_COMPONENT_TYPE,
        LAMBDA_FUNCTION_COMPONENT_TYPE
    ]
/]

[#macro shared_extension_cfredirect_deployment_setup occurrence ]

    [@DefaultLinkVariables enabled=false /]
    [@DefaultCoreVariables enabled=false /]
    [@DefaultEnvironmentVariables enabled=false /]
    [@DefaultBaselineVariables enabled=false /]

    [#local redirectScript = [
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
        "        var originDomain  = request.origin.custom.domainName;",
        "    }",
        "    if ( request.origin.s3 ) { ",
        "        var customHeaders = request.origin.s3.customHeaders;",
        "        var originDomain  = request.origin.s3.domainName;",
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
        "        request.headers['host'] = [{key: 'Host', value: originDomain}];",
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

[/#macro]
