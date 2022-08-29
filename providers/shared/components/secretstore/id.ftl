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
            "Names" : "Engine",
            "Types" : STRING_TYPE,
            "Description" : "The type of secret store",
            "Values" : [],
            "Mandatory" : true
        }
    ]
/]

[@addComponentDeployment
    type=SECRETSTORE_COMPONENT_TYPE
    defaultGroup="segment"
/]

[@addChildComponent
    type=SECRETSTORE_SECRET_COMPONENT_TYPE
    properties=[
            {
                "Type"  : "Description",
                "Value" : "A manually defined secret"
            }
        ]
    attributes=[
            {
                "Names" : "Generated",
                "Children" : [
                    {
                        "Names" : "Content",
                        "Description" : "A JSON object which contains the nonsensitve parts of the secret",
                        "Types" : OBJECT_TYPE,
                        "Default" : {
                            "username" : "admin"
                        }
                    },
                    {
                        "Names" : "SecretKey",
                        "Description" : "The key in the JSON secret to set the generated secret to",
                        "Types" : STRING_TYPE,
                        "Default" : "password"
                    }
                ]
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
                                "Types" : BOOLEAN_TYPE,
                                "Default" : false
                            }
                        ]
                    }
                ]
            },
            {
                "AttributeSet": SECRETSOURCE_ATTRIBUTESET_TYPE
            }
        ]
    parent=SECRETSTORE_COMPONENT_TYPE
    childAttribute="Secrets"
    linkAttributes="Secret"
/]
