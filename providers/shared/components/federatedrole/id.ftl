[#ftl]

[@addComponentDeployment
    type=FEDERATEDROLE_COMPONENT_TYPE
    defaultGroup="solution"
/]

[@addComponent
    type=FEDERATEDROLE_COMPONENT_TYPE
    properties=
        [
            {
                "Type" : "Description",
                "Value" : "Provides access to resources using an external identity source "
            }
        ]
    attributes=
        [
            {
                "Names" : [ "Extensions", "Fragment", "Container" ],
                "Description" : "Extensions to invoke as part of component processing",
                "Types" : ARRAY_OF_STRING_TYPE,
                "Default" : []
            },
            {
                "Names" : "Links",
                "Subobjects" : true,
                "Reference" : {
                    "Schema" : "attributeset",
                    "Type" : LINK_ATTRIBUTESET_TYPE
                }
            },
            {
                "Names" : "NoMatchBehaviour",
                "Description" : "When using rule assignements how to behave on no match",
                "Values" : [ "UseAuthenticatedRule", "Deny" ],
                "Default" : "Deny",
                "Types" : STRING_TYPE
            },
            {
                "Names" : "AllowUnauthenticatedUsers",
                "Description" : "Allow unautheniated users to use a federated role",
                "Default" : false,
                "Types" : BOOLEAN_TYPE
            }
        ]
/]


[@addChildComponent
    type=FEDERATEDROLE_ASSIGNMENT_COMPONENT_TYPE
    properties=
        [
            {
                "Type" : "Description",
                "Value" : "A rule based role assignment of permissions"
            },
            {
                "Type" : "Providers",
                "Value" : [ "aws" ]
            },
            {
                "Type" : "ComponentLevel",
                "Value" : "solution"
            }
        ]
    parent=FEDERATEDROLE_COMPONENT_TYPE
    childAttribute="Assignments"
    linkAttributes="Assignment"
    attributes=
        [
            {
                "Names" : "Type",
                "Description" : "How the assignment should be applied",
                "Values" : [ "Authenticated", "Unauthenticated", "Rule" ],
                "Mandatory" : true,
                "Types" : STRING_TYPE
            },
            {
                "Names" : "Rule",
                "Children" : [
                    {
                        "Names" : "Priority",
                        "Description" : "The order the rule should be evalutated in. lowest wins",
                        "Types" : NUMBER_TYPE,
                        "Default" : 100
                    },
                    {
                        "Names" : "Claim",
                        "Description" : "The user claim to evalutate",
                        "Types" : STRING_TYPE
                    },
                    {
                        "Names" : "MatchType",
                        "Description" : "How to match the claim value",
                        "Values" : [ "Equals", "Contains", "StartsWith", "NotEqual" ],
                        "Types" : STRING_TYPE
                    },
                    {
                        "Names" : "Value",
                        "Description" : "The value of the claim to match on",
                        "Types" : STRING_TYPE
                    },
                    {
                        "Names" : "Providers",
                        "Description" : "The link ids of the providers the assignment applies to",
                        "Types" : ARRAY_OF_STRING_TYPE
                    }
                ]
            },
            {
                "Names" : "Links",
                "Subobjects" : true,
                "Reference" : {
                    "Schema" : "attributeset",
                    "Type" : LINK_ATTRIBUTESET_TYPE
                }
            },
            {
                "Names" : "Permissions",
                "Children" : [
                    {
                        "Names" : "Decrypt",
                        "Types" : BOOLEAN_TYPE,
                        "Default" : false
                    },
                    {
                        "Names" : "AsFile",
                        "Types" : BOOLEAN_TYPE,
                        "Default" : false
                    },
                    {
                        "Names" : "AppData",
                        "Types" : BOOLEAN_TYPE,
                        "Default" : false
                    },
                    {
                        "Names" : "AppPublic",
                        "Types" : BOOLEAN_TYPE,
                        "Default" : false
                    }
                ]
            }
        ]
/]
