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

[#-- Not yet defined by cloud formation --]
[#assign CF_ACCESS_ID_OUTPUT_MAPPINGS =
    {
        REFERENCE_ATTRIBUTE_TYPE : {
            "UseRef" : true
        },
        CANONICAL_ID_ATTRIBUTE_TYPE : {
            "Attribute" : "S3CanonicalUserId"
        }
    }
]

[#assign outputMappings +=
    {
        AWS_CLOUDFRONT_DISTRIBUTION_RESOURCE_TYPE : CF_OUTPUT_MAPPINGS,
        AWS_CLOUDFRONT_ACCESS_ID_RESOURCE_TYPE : CF_ACCESS_ID_OUTPUT_MAPPINGS
    }
]

[#function getCFS3Origin id bucket accessId path=""]
    [#return
        [
            {
                "DomainName" : bucket + ".s3.amazonaws.com",
                "Id" : id,
                "S3OriginConfig" : {
                    "OriginAccessIdentity" : "origin-access-identity/cloudfront/" + accessId
                }
            } +
            attributeIfContent("OriginPath", path)
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
        headers=[]
        path=""
        httpConfig=
            {
                "OriginProtocolPolicy" : "https-only",
                "OriginSSLProtocols" : ["TLSv1.2"]
            }]
    [#return
        [
            {
                "DomainName" : domain,
                "Id" : id,
                "CustomOriginConfig" : httpConfig
            } +
            attributeIfContent("OriginCustomHeaders", asArray(headers)) +
            attributeIfContent("OriginPath", path)
        ]
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
    compress=false
    viewerProtocolPolicy="redirect-to-https"
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
                    attributeIfContent("Cookies", forwarded.Cookies!"") +
                    attributeIfContent("Headers", forwarded.Headers!"") +
                    attributeIfContent("QueryStringCacheKeys", forwarded.QueryStringCacheKeys!""),
                "SmoothStreaming" : smoothStreaming,
                "TargetOriginId" : asString(origin, "Id"),
                "ViewerProtocolPolicy" : viewerProtocolPolicy
            } +
            attributeIfContent("PathPattern", path) +
            attributeIfContent("AllowedMethods", methods.Allowed![], asArray(methods.Allowed![])) +
            attributeIfContent("CachedMethods", methods.Cached![], asArray(methods.Cached![])) +
            attributeIfContent("DefaultTTL", (ttl.Default)!"") +
            attributeIfContent("MaxTTL", (ttl.Max)!"") +
            attributeIfContent("MinTTL", (ttl.Min)!"") +
            attributeIfContent("TrustedSigners", trustedSigners![], asArray(trustedSigners![]))
        ]
    ]
[/#function]

[#function getCFAPIGatewayCacheBehaviour origin customHeaders=[] compress=true]
    [#return
        getCFCacheBehaviour(
            origin,
            "",
            {
                "Allowed" : [
                    "DELETE",
                    "GET",
                    "HEAD",
                    "OPTIONS",
                    "PATCH",
                    "POST",
                    "PUT"
                ],
                "Cached" : [
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
                ] + customHeaders,
                "QueryString" : true
            },
            compress
        )
    ]
[/#function]

[#function getCFSPACacheBehaviour origin path="" ttl={"Default" : 600}  compress=true]
    [#return
        getCFCacheBehaviour(
            origin,
            path,
            {
                "Allowed" : [
                    "GET",
                    "HEAD",
                    "OPTIONS"
                ],
                "Cached" : [
                    "GET",
                    "HEAD"
                ]
            },
            ttl,
            {
                "Cookies" : {
                    "Forward" : "all"
                },
                "QueryString" : true
            },
            compress
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

[#function getCFCertificate id httpsProtocolPolicy assumeSNI=true ]
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
            "MinimumProtocolVersion" : httpsProtocolPolicy,
            "SslSupportMethod" : assumeSNI?then("sni-only", "vip")
        }
    ]
[/#function]

[#function getCFGeoRestriction locations blacklist=false]
    [#return
        valueIfContent(
            {
                "GeoRestriction" : {
                    "Locations" :
                        asArray(locations![]),
                    "RestrictionType" :
                        blacklist?then(
                            "blacklist",
                            "whitelist"
                        )
                }
            },
            locations![]
        )
    ]
[/#function]

[#function getErrorResponse errorCode responseCode=200 path="/index.html" ttl={}]
    [#return
        [
            {
                "ErrorCode" : errorCode,
                "ResponseCode" : responseCode,
                "ResponsePagePath" : path
            } +
            attributeIfContent("ErrorCachingMinTTL", ttl.Min!"")
        ]
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
    [@cfResource
        mode=mode
        id=id
        type="AWS::CloudFront::Distribution"
        properties=
            {
                "DistributionConfig" :
                    {
                        "Enabled" : isEnabled,
                        "HttpVersion" : httpVersion
                    } +
                    attributeIfContent("Aliases", aliases) +
                    attributeIfContent("CacheBehaviors", cacheBehaviours) +
                    attributeIfContent("Comment", comment) +
                    attributeIfContent("CustomErrorResponses", customErrorResponses) +
                    attributeIfContent("DefaultCacheBehavior", defaultCacheBehaviour, asArray(defaultCacheBehaviour)[0]) +
                    attributeIfContent("DefaultRootObject", defaultRootObject) +
                    attributeIfContent("Logging", logging) +
                    attributeIfContent("Origins", origins) +
                    attributeIfContent("PriceClass", priceClass) +
                    attributeIfContent("Restrictions", restrictions) +
                    attributeIfContent("ViewerCertificate", certificate) +
                    attributeIfContent("WebACLId", getReference(wafAclId))
            }
        outputs=CF_OUTPUT_MAPPINGS
        dependencies=dependencies
    /]
[/#macro]