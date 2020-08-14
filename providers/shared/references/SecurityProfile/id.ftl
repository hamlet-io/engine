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
        },
        {
            "Names" : "IPSecVPN",
            "Children" : [
                {
                    "Names" : "TunnelInsideCidr",
                    "Type" : STRING_TYPE
                },
                {
                    "Names" : "IKEVersions",
                    "Type" : ARRAY_OF_STRING_TYPE
                },
                {
                    "Names" : "Rekey",
                    "Children" : [
                        {
                            "Names" : "MarginTime",
                            "Type" : NUMBER_TYPE
                        },
                        {
                            "Names" : "FuzzPercentage",
                            "Type" : NUMBER_TYPE
                        }
                    ]
                },
                {
                    "Names" : "ReplayWindowSize",
                    "Type" : NUMBER_TYPE
                },
                {
                    "Names" : "DeadPeerDetectionTimeout",
                    "Type" : NUMBER_TYPE
                },
                {
                    "Names" : "Phase1",
                    "Children" : [
                        {
                            "Names" : "EncryptionAlgorithms",
                            "Type" : ARRAY_OF_STRING_TYPE
                        },
                        {
                            "Names" : "IntegrityAlgorithms",
                            "Type" : ARRAY_OF_STRING_TYPE
                        },
                        {
                            "Names" : "DiffeHellmanGroups",
                            "Type" : ARRAY_OF_NUMBER_TYPE
                        }
                        {
                            "Names" : "Lifetime",
                            "Type" : NUMBER_TYPE
                        }
                    ]
                },
                {
                    "Names" : "Phase2",
                    "Children" : [
                        {
                            "Names" : "EncryptionAlgorithms",
                            "Type" : ARRAY_OF_STRING_TYPE
                        },
                        {
                            "Names" : "IntegrityAlgorithms",
                            "Type" : ARRAY_OF_STRING_TYPE
                        },
                        {
                            "Names" : "DiffeHellmanGroups",
                            "Type" : ARRAY_OF_NUMBER_TYPE
                        }
                        {
                            "Names" : "Lifetime",
                            "Type" : NUMBER_TYPE
                        }
                    ]
                }
            ]
        },
        {
            "Names" : "filetransfer",
            "Children" : [
                {
                    "Names" : "EncryptionPolicy",
                    "Type" : STRING_TYPE
                }
            ]
        }
    ]
/]
