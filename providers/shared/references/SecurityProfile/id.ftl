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
                            "Types" : STRING_TYPE,
                            "Description" : "Defines the TLS encryption profile used for HTTPS connections"
                        }
                    ]
                },
                {
                    "Names" : "application",
                    "Children" : [
                        {
                            "Names" : "HTTPSProfile",
                            "Types" : STRING_TYPE,
                            "Description" : "Defines the TLS encryption profile used for HTTPS connections"
                        },
                        {
                            "Names" : "WAFProfile",
                            "Types" : STRING_TYPE
                        },
                        {
                            "Names" : "WAFValueSet",
                            "Types" : STRING_TYPE
                        }
                    ]
                },
                {
                    "Names" : "classic",
                    "Children" : [
                        {
                            "Names" : "HTTPSProfile",
                            "Types" : STRING_TYPE,
                            "Description" : "Defines the TLS encryption profile used for HTTPS connections"
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
                    "Types" : STRING_TYPE,
                    "Description" : "Defines the TLS encryption profile used for HTTPS connections"
                },
                {
                    "Names" : "GatewayHTTPSProfile",
                    "Types" : STRING_TYPE,
                    "Description" : "Defines the TLS encryption profile used for HTTPS connections",
                    "Default" : "TLS_1_0"
                },
                {
                    "Names" : "ProtocolPolicy",
                    "Types" : STRING_TYPE
                },
                {
                    "Names" : "WAFProfile",
                    "Types" : STRING_TYPE
                },
                {
                    "Names" : "WAFValueSet",
                    "Types" : STRING_TYPE
                }
            ]
        },
        {
            "Names" : "cdn",
            "Children" : [
                {
                    "Names" : "HTTPSProfile",
                    "Description" : "Defines the TLS encryption profile used for HTTPS connections",
                    "Types" : STRING_TYPE
                },
                {
                    "Names" : "WAFProfile",
                    "Types" : STRING_TYPE
                },
                {
                    "Names" : "WAFValueSet",
                    "Types" : STRING_TYPE
                }
            ]
        },
        {
            "Names" : "db",
            "Children" : [
                {
                    "Names" : "SSLCertificateAuthority",
                    "Types" : STRING_TYPE
                }
            ]
        },
        {
            "Names" : "es",
            "Children" : [
                {
                    "Names" : "ProtocolPolicy",
                    "Description": "Define the protocols the ES endpoints are available on",
                    "Types" : STRING_TYPE,
                    "Values" : [ "https-only", "http-https", "http-only" ],
                    "Default" : "https-only"
                },
                {
                    "Names" : "HTTPSProfile",
                    "Types" : STRING_TYPE,
                    "Description" : "Defines the TLS encryption profile used for HTTPS connections"
                },
                {
                    "Names" : "NodeTransitEncryption",
                    "Types" : BOOLEAN_TYPE,
                    "Description" : "Require the use of node to node transit encryption"
                }
            ]
        },
        {
            "Names" : "IPSecVPN",
            "Children" : [
                {
                    "Names" : "TunnelInsideCidr",
                    "Types" : STRING_TYPE
                },
                {
                    "Names" : "IKEVersions",
                    "Types" : ARRAY_OF_STRING_TYPE
                },
                {
                    "Names" : "StartupAction",
                    "Description" : "Initiation behaviour for vpn",
                    "Types" : STRING_TYPE,
                    "Values" : [ "add", "start" ]
                },
                {
                    "Names" : "Rekey",
                    "Children" : [
                        {
                            "Names" : "MarginTime",
                            "Types" : NUMBER_TYPE
                        },
                        {
                            "Names" : "FuzzPercentage",
                            "Types" : NUMBER_TYPE
                        }
                    ]
                },
                {
                    "Names" : "ReplayWindowSize",
                    "Types" : NUMBER_TYPE
                },
                {
                    "Names" : "DeadPeerDetectionTimeout",
                    "Types" : NUMBER_TYPE
                },
                {
                    "Names" : "DeadPeerDetectionAction",
                    "Types" : STRING_TYPE,
                    "Values" : [ "clear", "none", "restart" ]
                },
                {
                    "Names" : "Phase1",
                    "Children" : [
                        {
                            "Names" : "EncryptionAlgorithms",
                            "Types" : ARRAY_OF_STRING_TYPE
                        },
                        {
                            "Names" : "IntegrityAlgorithms",
                            "Types" : ARRAY_OF_STRING_TYPE
                        },
                        {
                            "Names" : "DiffeHellmanGroups",
                            "Types" : ARRAY_OF_NUMBER_TYPE
                        }
                        {
                            "Names" : "Lifetime",
                            "Types" : NUMBER_TYPE
                        }
                    ]
                },
                {
                    "Names" : "Phase2",
                    "Children" : [
                        {
                            "Names" : "EncryptionAlgorithms",
                            "Types" : ARRAY_OF_STRING_TYPE
                        },
                        {
                            "Names" : "IntegrityAlgorithms",
                            "Types" : ARRAY_OF_STRING_TYPE
                        },
                        {
                            "Names" : "DiffeHellmanGroups",
                            "Types" : ARRAY_OF_NUMBER_TYPE
                        }
                        {
                            "Names" : "Lifetime",
                            "Types" : NUMBER_TYPE
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
                    "Types" : STRING_TYPE
                }
            ]
        }
    ]
/]
