[#ftl]

[@addComponent
    type=FEDERATEDROLE_COMPONENT_TYPE
    properties=
        [
            {
                "Type" : "Description",
                "Value" : "Provides access to resources using an external identity source "
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
    attributes=
        [
            {
                "Names" : ["Fragment", "Container"],
                "Type" : STRING_TYPE,
                "Default" : ""
            },
            {
                "Names" : "Links",
                "Subobjects" : true,
                "Children" : linkChildrenConfiguration
            },
            {
                "Names" : "NoMatchBehaviour",
                "Description" : "When using rule assignements how to behave on no match",
                "Values" : [ "UseAuthenticatedRule", "Deny" ],
                "Default" : "Deny",
                "Type" : STRING_TYPE
            },
            {
                "Names" : "AllowUnauthenticatedUsers",
                "Description" : "Allow unautheniated users to use a federated role",
                "Default" : false,
                "Type" : BOOLEAN_TYPE
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
                "Type" : STRING_TYPE
            },
            {
                "Names" : "Rule",
                "Children" : [
                    {
                        "Names" : "Priority",
                        "Description" : "The order the rule should be evalutated in. lowest wins",
                        "Type" : NUMBER_TYPE,
                        "Default" : 100
                    },
                    {
                        "Names" : "Claim",
                        "Description" : "The user claim to evalutate",
                        "Type" : STRING_TYPE
                    },
                    {
                        "Names" : "MatchType",
                        "Description" : "How to match the claim value",
                        "Values" : [ "Equals", "Contains", "StartsWith", "NotEqual" ],
                        "Type" : STRING_TYPE
                    },
                    {
                        "Names" : "Value",
                        "Description" : "The value of the claim to match on",
                        "Type" : STRING_TYPE
                    },
                    {
                        "Names" : "Providers",
                        "Description" : "The link ids of the providers the assignment applies to",
                        "Type" : ARRAY_OF_STRING_TYPE
                    }
                ]
            },
            {
                "Names" : "Links",
                "Subobjects" : true,
                "Children" : linkChildrenConfiguration
            },
            {
                "Names" : "Permissions",
                "Children" : [
                    {
                        "Names" : "Decrypt",
                        "Type" : BOOLEAN_TYPE,
                        "Default" : false
                    },
                    {
                        "Names" : "AsFile",
                        "Type" : BOOLEAN_TYPE,
                        "Default" : false
                    },
                    {
                        "Names" : "AppData",
                        "Type" : BOOLEAN_TYPE,
                        "Default" : false
                    },
                    {
                        "Names" : "AppPublic",
                        "Type" : BOOLEAN_TYPE,
                        "Default" : false
                    }
                ]
            }
        ]
/]