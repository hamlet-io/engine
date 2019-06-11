[#ftl]

[#assign SEED_RESOURCE_TYPE = "seed" ]

[#function formatSegmentSeedId ]
    [#return formatSegmentResourceId(SEED_RESOURCE_TYPE)]
[/#function]

[@addComponent
    type=BASELINE_COMPONENT_TYPE
    properties=
        [
            {
                "Type"  : "Description",
                "Value" : "A set of resources required for every segment deployment"
            },
            {
                "Type" : "Providers",
                "Value" : [ "aws" ]
            },
            {
                "Type" : "ComponentLevel",
                "Value" : "segment"
            }
        ]
/]

[@addComponentResourceGroup
    type=BASELINE_COMPONENT_TYPE
    attributes=
        [
            {
                "Names" : "Active",
                "Type" : BOOLEAN_TYPE,
                "Default" : false
            },
            {
                "Names" : "Seed",
                "Children" : [
                    {
                        "Names" : "Length",
                        "Type" : NUMBER_TYPE,
                        "Default" : 10
                    }
                ]
            }
        ]
/]

[@addChildComponent
    type=BASELINE_DATA_COMPONENT_TYPE
    properties=
        [
            {
                "Type" : "Description",
                "Value" : "A segment shared data store"
            },
            {
                "Type" : "Providers",
                "Value" : [ "aws" ]
            },
            {
                "Type" : "ComponentLevel",
                "Value" : "segment"
            }
        ]
    parent=BASELINE_COMPONENT_TYPE
    childAttribute="DataBuckets"
    linkAttributes="DataBucket"
/]

[@addComponentResourceGroup
    type=BASELINE_DATA_COMPONENT_TYPE
    attributes=
        [
            {
                "Names" : "Role",
                "Type" : STRING_TYPE,
                "Values" : [ "appdata", "operations" ],
                "Mandatory" : true
            },
            {
                "Names" : "Lifecycles",
                "Subobjects" : true,
                "Children" : [
                    {
                        "Names" : "Prefix",
                        "Types" : STRING_TYPE,
                        "Description" : "The prefix to apply the lifecycle to"
                    }
                    {
                        "Names" : "Expiration",
                        "Types" : [STRING_TYPE, NUMBER_TYPE],
                        "Description" : "Provide either a date or a number of days",
                        "Default" : "_operations"
                    },
                    {
                        "Names" : "Offline",
                        "Types" : [STRING_TYPE, NUMBER_TYPE],
                        "Description" : "Provide either a date or a number of days",
                        "Default" : "_operations"
                    }
                ]
            },
            {
                "Names" : "Versioning",
                "Type" : BOOLEAN_TYPE,
                "Default" : false
            },
            {
                "Names" : "Links",
                "Subobjects" : true,
                "Children" : linkChildrenConfiguration
            },
            {
                "Names" : "Notifications",
                "Subobjects" : true,
                "Children" : s3NotificationChildConfiguration
            }
        ]
/]

[@addChildComponent
    type=BASELINE_KEY_COMPONENT_TYPE
    properties=
        [
            {
                "Type" : "Description",
                "Value" : "Shared security keys for a segment"
            },
            {
                "Type" : "Providers",
                "Value" : [ "aws" ]
            },
            {
                "Type" : "ComponentLevel",
                "Value" : "segment"
            }
        ]
    parent=BASELINE_COMPONENT_TYPE
    childAttribute="Keys"
    linkAttributes="Key"
/]

[@addComponentResourceGroup
    type=BASELINE_KEY_COMPONENT_TYPE
    attributes=
        [
            {
                "Names" : "Engine",
                "Type" : STRING_TYPE,
                "Values" : [ "cmk", "ssh", "oai" ],
                "Mandatory" : true
            },
            {
                "Names" : "Links",
                "Subobjects" : true,
                "Children" : linkChildrenConfiguration
            }
        ]
/]
