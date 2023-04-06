[#ftl]

[@addAttributeSet
    type=CDNORIGIN_ATTRIBUTESET_TYPE
    properties=[
        {
                "Type"  : "Description",
                "Value" : "Configuration for a CDN origin"
        }]
    attributes=[
        {
            "Names" : "ConnectionTimeout",
            "Description" : "How long to wait until a response is received from the origin",
            "Types" : NUMBER_TYPE,
            "Default" : 30
        },
        {
            "Names" : "TLSProtocols",
            "Description" : "When using a TLS backend the protocols the CDN will use as a client",
            "Types" : ARRAY_OF_STRING_TYPE,
            "Values" : [ "TLSv1.2", "TLSv1.1", "TLSv1", "SSLv3" ],
            "Default" : [ "TLSv1.2" ]
        },
        {
            "Names" : "BasePath",
            "Description" : "The base path at the origin destination",
            "Types" : STRING_TYPE,
            "Default" : ""
        },
        {
            "Names" : [ "OriginLink", "Link"],
            "Description" : "A link to the origin that requests will route to",
            "Mandatory" : true,
            "AttributeSet" : LINK_ATTRIBUTESET_TYPE
        },
        {
            "Names" : "RequestForwarding",
            "Description" : "Controls how the request is forwarded to the origin",
            "Children" : [
                {
                    "Names" : "AdditionalHeaders",
                    "Description": "Headers to add when forwarding the request to the origin",
                    "SubObjects": true,
                    "Children" : [
                        {
                            "Names" : "Name",
                            "Description" : "The name of the header ( object id used if not provided)",
                            "Types": STRING_TYPE
                        },
                        {
                            "Names": "Value",
                            "Description" : "The value of the header",
                            "Types": STRING_TYPE,
                            "Mandatory": true
                        }
                    ]
                },
                {
                    "Names": "Policy",
                    "Description": "How the request forwarding policy is determined - LinkType = Use a predefined policy for the link type, custom = your own",
                    "Values" : [ "LinkType", "Custom" ],
                    "Default" : "LinkType"
                },
                {
                    "Names" : "Policy:Custom",
                    "Children" : [
                        {
                            "Names" : "Cookies",
                            "Description" : "A list of cookie names to forward to the origin ( _all - all cookies )",
                            "Types" : ARRAY_OF_STRING_TYPE,
                            "Default" : [ "_all" ]
                        },
                        {
                            "Names" : "Headers",
                            "Description" : "A list of header keys to forward to the origin ( _all - all headers, _cdn - CDN included headers )",
                            "Types" : ARRAY_OF_STRING_TYPE,
                            "Default" : [ "_all" ]
                        },
                        {
                            "Names" : "QueryParams",
                            "Description" : "A list of query parameter names to forward ( _all - all parameters )",
                            "Types" : ARRAY_OF_STRING_TYPE,
                            "Default" : [ "_all" ]
                        },
                        {
                            "Names" : "QueryParamExclude",
                            "Description" : "Whether the QueryParams is a whitelist or a blacklist. ie Should the QueryParams be excluded",
                            "Types" : BOOLEAN_TYPE,
                            "Default" : false
                        },
                        {
                            "Names" : "Methods",
                            "Description" : "The HTTP Methods that will be forwarded to the origin",
                            "Types" : ARRAY_OF_STRING_TYPE,
                            "Values" : [ "GET", "HEAD", "OPTIONS", "PUT", "PATCH", "POST", "DELETE"],
                            "Default" : [ "GET", "HEAD", "OPTIONS", "PUT", "PATCH", "POST", "DELETE"]
                        }
                    ]
                }
            ]
        }
    ]
/]
