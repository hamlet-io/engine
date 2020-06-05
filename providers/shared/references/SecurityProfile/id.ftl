[#ftl]

[@addReference
    type=SECURITYPROFILE_REFERENCE_TYPE
    pluralType="SecurityProfiles"
    properties=[
            {
                "Type"  : "Description",
                "Value" : "Security Configuration Options"
            }
        ]
    attributes=[
        {
            "Names" : "lb",
            "Children" : [
                {
                    "Names" : "network",
                    "Children" : [
                        {
                            "Names" : "HTTPSProfile",
                            "Type" : STRING_TYPE
                        }
                    ]
                },
                {
                    "Names" : "application",
                    "Children" : [
                        {
                            "Names" : "HTTPSProfile",
                            "Type" : STRING_TYPE
                        },
                        {
                            "Names" : "WAFProfile",
                            "Type" : STRING_TYPE
                        },
                        {
                            "Names" : "WAFValueSet",
                            "Type" : STRING_TYPE
                        }
                    ]
                },
                {
                    "Names" : "classic",
                    "Children" : [
                        {
                            "Names" : "HTTPSProfile",
                            "Type" : STRING_TYPE
                        }
                    ]
                }
            ]
        },
        {
            "Names" : "apigateway",
            "Children" : [
                {
                    "Names" : [ "CDNHTTPSProfile", "HTTPSProfile"],
                    "Type" : STRING_TYPE
                },
                {
                    "Names" : "GatewayHTTPSProfile",
                    "Type" : STRING_TYPE,
                    "Default" : "TLS_1_0"
                },
                {
                    "Names" : "ProtocolPolicy",
                    "Type" : STRING_TYPE
                },
                {
                    "Names" : "WAFProfile",
                    "Type" : STRING_TYPE
                },
                {
                    "Names" : "WAFValueSet",
                    "Type" : STRING_TYPE
                }
            ]
        },
        {
            "Names" : "cdn",
            "Children" : [
                {
                    "Names" : "HTTPSProfile",
                    "Type" : STRING_TYPE
                },
                {
                    "Names" : "WAFProfile",
                    "Type" : STRING_TYPE
                },
                {
                    "Names" : "WAFValueSet",
                    "Type" : STRING_TYPE
                }
            ]
        },
        {
            "Names" : "db",
            "Children" : [
                {
                    "Names" : "SSLCertificateAuthority",
                    "Type" : STRING_TYPE
                }
            ]
        },
        {
            "Names" : "es",
            "Children" : [
                {
                    "Names" : "ProtocolPolicy",
                    "Type" : STRING_TYPE,
                    "Values" : [ "https-only", "http-https", "http-only" ]
                }
            ]
        }
    ]
/]
