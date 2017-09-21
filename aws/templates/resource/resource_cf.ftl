[#-- CloudFront --]

[#assign CF_OUTPUT_MAPPINGS =
    {
        REFERENCE_ATTRIBUTE_TYPE : {
            "UseRef" : true
        },
        DNS_ATTRIBUTE_TYPE : { 
            "Attribute" : "DomainName"
        }
    }
]
[#assign outputMappings +=
    {
        CF_RESOURCE_TYPE : CF_OUTPUT_MAPPINGS
    }
]

[#function getCFS3Origin id bucket accessId path=""]
    [#return
        [
            {
                "DomainName" : bucket + ".s3.amazonaws.com",
                "Id" : id,
                "S3OriginConfig" : {
                    "OriginAccessIdentity" : accessId
                }
            } + 
            path?has_content?then(
                {
                    "OriginPath" : path
                },
                {}
            )
        ]
    ]
[/#function]

[#function getCFHTTPHeader name value]
    [#return
        {
          "HeaderName" : name,
          "HeaderValue" : value
        }
    ]
[/#function]

[#function getCFHTTPOrigin id domain
        httpConfig=
            {
                "OriginProtocolPolicy" : "https-only",
                "OriginSSLProtocols" : ["TLSv1.2"]
            }
        headers=[]
        path="" ]
    [#return
        [
            {
                "DomainName" : domain,
                "Id" : id,
                "CustomOriginConfig" : httpConfig
            } + 
            asArray(headers)?has_content?then(
                {
                    "OriginCustomHeaders" : asArray(headers)
                },
                {}
            ) +            
            path?has_content?then(
                {
                    "OriginPath" : path
                },
                {}
            )
        ]
    ]
[/#function]

[#function getCFAPIGatewayOrigin id apiId headers=[] path=""]
    [#return
        getCFHTTPOrigin(
            id,
            {
                "Fn::Join" : [
                    ".",
                    [
                        getReference(apiId),
                        "execute-api." + regionId + ".amazonaws.com"
                    ]
                ]
            },
            headers,
            path
        )
    ]
[/#function]

[#function getCFCacheBehaviour origin
    path=""
    methods={}
    ttl={}
    forwarded=
        {
            "QueryString" : true
        }
    viewerProtocolPolicy="redirect-to-https"
    compress=false
    smoothStreaming=false
    trustedSigners=[]
]
    [#return
        [
            {
                "Compress" : compress,
                "ForwardedValues" :
                    {
                        "QueryString" : forwarded.QueryString
                    } + 
                    forwarded.Cookies?has_content?then(
                        {
                            "Cookies" : forwarded.Cookies
                        },
                        {}
                    ) +
                    forwarded.Headers?has_content?then(
                        {
                            "Headers" : forwarded.Headers
                        },
                        {}
                    ) +
                    forwarded.QueryStringCacheKeys?has_content?then(
                        {
                            "QueryStringCacheKeys" : forwarded.QueryStringCacheKeys
                        },
                        {}
                    ),
                "SmoothStreaming" : smoothStreaming,
                "TargetOriginId" : asString(origin, "Id"),
                "ViewerProtocolPolicy" : viewerProtocolPolicy
            } + 
            path?has_content?then(
                {
                    "PathPattern" : path
                },
                {}
            ) + 
            methods.Allowed?has_content?then(
                {
                    "AllowedMethods" : asArray(methods.Allowed)
                },
                {}
            ) + 
            methods.Cached?has_content?then(
                {
                    "CachedMethods" : asArray(methods.Cached)
                },
                {}
            ) +
            ttl.Default?has_content?then(
                {
                    "DefaultTTL" : ttl.Default
                },
                {}
            ) +
            ttl.Max?has_content?then(
                {
                    "MaxTTL" : ttl.Max
                },
                {}
            ) +
            ttl.Min?has_content?then(
                {
                    "MinTTL" : ttl.Min
                },
                {}
            ) +
            trustedSigners?has_content?then(
                {
                    "trustedSigners" : asArray(trustedSigners)
                },
                {}
            )
        ]
    ]
[/#function]

[#function getCFAPIGatewayCacheBehaviour origin]
    [#return
        getCFCacheBehaviour(
            origin,
            "",
            {
                "AllowedMethods" : [
                    "DELETE",
                    "GET",
                    "HEAD",
                    "OPTIONS",
                    "PATCH",
                    "POST",
                    "PUT"
                ],
                "CachedMethods" : [
                    "GET",
                    "HEAD"
                ]
            },
            {
                "Default" : 0,
                "Min" : 0,
                "Max" : 0
            },
            {
                "Cookies" : {
                    "Forward" : "all"
                },
                "Headers" : [
                    "Accept",
                    "Accept-Charset",
                    "Accept-Datetime",
                    "Accept-Language",
                    "Authorization",
                    "Origin",
                    "Referer"
                ],
                "QueryString" : true
            }
        )
    ]
[/#function]

[#function getCFLogging bucket prefix="" includeCookies=false]
    [#return
        {
            "Bucket" : bucket + ".s3.amazonaws.com",
            "IncludeCookies" : includeCookies,
            "Prefix" :
                formatRelativePath("CLOUDFRONTLogs", prefix)
        }
    ]
[/#function]

[#function getCFCertificate id assumeSNI=true]
    [#local acmCertificateArn = getExistingReference(id, ARN_ATTRIBUTE_TYPE, "us-east-1") ]
    [#return
        {
            "AcmCertificateArn" :
                acmCertificateArn?has_content?then( 
                    acmCertificateArn,
                    formatRegionalArn(
                        "acm",
                        formatTypedArnResource(
                            "certificate",
                            id,
                            "/"
                        ),
                        "us-east-1"
                    )
                ),
            "MinimumProtocolVersion" : "TLSv1",
            "SslSupportMethod" : assumeSNI?then("sni-only", "vip")
        }
    ]
[/#function]

[#function getCFGeoRestriction locations blacklist=false]
    [#return
        locations?has_content?then(
            {
                "GeoRestriction" : {
                    "Locations" :
                        asArray(locations),
                    "RestrictionType" :
                        blacklist?then(
                            "blacklist",
                            "whitelist"
                        )
                }
            },
            {}
        )
    ]
[/#function]

[#macro createCFDistribution mode id dependencies=""
    aliases=[]
    cacheBehaviours=[]
    certificate={}
    comment=""
    customErrorResponses=[]
    defaultCacheBehaviour={}
    defaultRootObject=""
    isEnabled=true
    httpVersion="http2"
    logging={}
    origins=[]
    priceClass=""
    restrictions={}
    wafAclId=""
]
    [@cfTemplate 
        mode=mode
        id=id
        type="AWS::CloudFront::Distribution"
        properties=
            {
                "DistributionConfig" :
                    aliases?has_content?then(
                        {
                            "Aliases" : aliases
                        },
                        {}
                    ) +
                    cacheBehaviours?has_content?then(
                        {
                            "CacheBehaviors" : cacheBehaviours
                        },
                        {}
                    ) +
                    comment?has_content?then(
                        {
                            "Comment" : comment
                        },
                        {}
                    ) +
                    customErrorResponses?has_content?then(
                        {
                            "CustomErrorResponses" : aliases
                        },
                        {}
                    ) +
                    defaultCacheBehaviour?has_content?then(
                        {
                            "DefaultCacheBehavior" : asArray(defaultCacheBehaviour)[0]
                        },
                        {}
                    ) +
                    defaultRootObject?has_content?then(
                        {
                            "DefaultRootObject" : defaultRootObject
                        },
                        {}
                    ) +
                    {
                        "Enabled" : isEnabled,
                        "HttpVersion" : httpVersion
                    } +
                    logging?has_content?then(
                        {
                            "Logging" : logging
                        },
                        {}
                    ) +
                    origins?has_content?then(
                        {
                            "Origins" : origins
                        },
                        {}
                    ) +
                    priceClass?has_content?then(
                        {
                            "PriceClass" : priceClass
                        },
                        {}
                    ) +
                    restrictions?has_content?then(
                        {
                            "Restrictions" : restrictions
                        },
                        {}
                    ) +
                    certificate?has_content?then(
                        {
                            "ViewerCertificate" : certificate
                        },
                        {}
                    ) +
                    wafAcl?has_content?then(
                        {
                            "WebACLId" : getReference(wafAcl)
                        },
                        {}
                    )
            }
        outputs=CF_OUTPUT_MAPPINGS
        dependencies=dependencies
    /]
[/#macro]