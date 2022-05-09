[#ftl]

[@addComponent
    type=CERTIFICATEAUTHORITY_COMPONENT_TYPE
    properties=
        [
            {
                "Type"  : "Description",
                "Value" : "A private x509 certficate authority"
            }
        ]
    attributes=
        [
            {
                "Names" : "Links",
                "SubObjects" : true,
                "AttributeSet" : LINK_ATTRIBUTESET_TYPE
            },
            {
                "Names": "Level",
                "Description": "The level of the authority",
                "Values": ["Root", "Subordinate"],
                "Default" : "Root"
            },
            {
                "Names": "level:Subordinate",
                "Children" : [
                    {
                        "Names" : "MaxLevels",
                        "Description" : "The maximum number of subordinate CA's permitted under this CA",
                        "Types": NUMBER_TYPE,
                        "Default": 0
                    },
                    {
                        "Names": "ParentAuthority",
                        "Children": [
                            {
                                "Names": "Link",
                                "AttributeSet": LINK_ATTRIBUTESET_TYPE
                            }
                        ]
                    }
                ]
            },
            {
                "Names": "Validity",
                "Description" : "Certificate Validity",
                "Children": [
                    {
                        "Names" : "Length",
                        "Description" : "How long (in days) the certificate is valid for",
                        "Types" : NUMBER_TYPE,
                        "Default" : 1095
                    }
                ]
            },
            {
                "Names" : "Subject",
                "Children" : [
                    {
                        "Names" : "CommonName",
                        "Description" : "The Common name of the root CA",
                        "Children" : hostNameChildConfiguration
                    }
                ]
            },
            {
                "Names": "KeyAlgorithm",
                "Description": "The algorithm used for the private key",
                "Values" : [ "EC_prime256v1", "EC_secp384r1", "RSA_2048", "RSA_4096"],
                "Default": "RSA_2048"
            },
            {
                "Names": "SigningAlgorithm",
                "Description": "The algorithm used for signing certificates",
                "Values": [ "SHA256WITHECDSA", "SHA256WITHRSA", "SHA384WITHECDSA", "SHA384WITHRSA", "SHA512WITHECDSA", "SHA512WITHRSA"],
                "Default": "SHA256WITHRSA"
            }
        ]
/]

[@addComponentDeployment
    type=CERTIFICATEAUTHORITY_COMPONENT_TYPE
    defaultGroup="solution"
/]
