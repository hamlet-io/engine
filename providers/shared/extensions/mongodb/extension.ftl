[#ftl]

[@addExtension
    id="mongodb"
    aliases=[
        "_mongodb"
    ]
    description=[
        "Basic mongodb deployment"
    ]
    supportedTypes=[
        ECS_SERVICE_COMPONENT_TYPE,
        ECS_TASK_COMPONENT_TYPE,
        CONTAINERSERVICE_COMPONENT_TYPE,
        CONTAINERTASK_COMPONENT_TYPE
    ]
/]

[#macro shared_extension_mongodb_setup occurrence ]

    [@Attributes image="mongodb" /]
    [@Volume "mongodb" "/data/db" "/codeontap/mongodb/db" /]

[/#macro]
