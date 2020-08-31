[#ftl]

[@addComponent
    type=SECRETSTORE_COMPONENT_TYPE
    properties=[
            {
                "Type"  : "Description",
                "Value" : "A Secret Manager"
            }
        ]
    attributes=[
        {
            "Names" : "DeploymentGroup",
            "Type" : STRING_TYPE,
            "Default" : "segment"
        }
    ]
/]

[@addChildComponent
    type=SECRETSTORE_SECRET_COMPONENT_TYPE
    properties=[
            {
                "Type"  : "Description",
                "Value" : "A Secret stored within a given SecretStore."
            }
        ]
    attributes=[
            {
                "Names" : "Source",
                "Type" : STRING_TYPE,
                "Values" : [ "user", "generated" ],
                "Default" : "user"
            },
            {
                "Names" : "Lifecycle",
                "Description" : "The lifecycle for a given Secret.",
                "Children" : [
                    {
                        "Names" : "Rotation",
                        "Description" : "The Secret rotation schedule, in number of days - accepts rate() or cron() formats.",
                        "Children" : [
                            {
                                "Names" : "Enabled",
                                "Description" : "Enable Secret rotation.",
                                "Type" : BOOLEAN_TYPE,
                                "Default" : false
                            }
                        ]
                    }
                ]
            },
            {
                "Names" : "Requirements",
                "Description" : "Format requirements for the Secret.",
                "Children" : [
                    {
                        "Names" : "MinLength",
                        "Description" : "The minimum character length for the Secret.",
                        "Type" : NUMBER_TYPE,
                        "Default" : 20
                    },
                    {
                        "Names" : "MaxLength",
                        "Description" : "The maximum character length for the Secret.",
                        "Type" : NUMBER_TYPE,
                        "Default" : 30
                    },
                    {
                        "Names" : "IncludeUpper",
                        "Description" : "Include upper-case characters in Secret.",
                        "Type" : BOOLEAN_TYPE,
                        "Mandatory" : true
                    },
                    {
                        "Names" : "IncludeLower",
                        "Description" : "Include lower-case characters in Secret.",
                        "Type" : BOOLEAN_TYPE,
                        "Mandatory" : true
                    },
                    {
                        "Names" : "IncludeSpecial",
                        "Description" : "Include special characters in Secret.",
                        "Type" : BOOLEAN_TYPE,
                        "Mandatory" : false
                    },
                    {
                        "Names" : "ExcludedCharacters",
                        "Description" : "Characters that must be excluded from Secret.",
                        "Type" : ARRAY_OF_STRING_TYPE
                    }
                ]
            }
        ]
    parent=SECRETSTORE_COMPONENT_TYPE
    childAttribute="Secrets"
    linkAttributes="Secret"
/]
