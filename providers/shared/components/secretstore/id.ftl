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
    attributes=
        secretConfiguration +
        secretTemplateConfiguration +
        secretRotationConfiguration
    parent=SECRETSTORE_COMPONENT_TYPE
    childAttribute="Secrets"
    linkAttributes="Secret"
/]
