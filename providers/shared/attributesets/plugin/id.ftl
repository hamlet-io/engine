[#ftl]

[@addAttributeSet
    type=PLUGIN_ATTRIBUTESET_TYPE
    properties=[
        {
                "Type"  : "Description",
                "Value" : "Defines a CMDB plugin and how its loaded"
        }]
    attributes=[
        {
            "Names" : "Enabled",
            "Description" : "To enable loading the plugin",
            "Types" : BOOLEAN_TYPE,
            "Default" : true
        },
        {
            "Names" : "Required",
            "Types" : BOOLEAN_TYPE,
            "Description" : "Ensure the plugin loads at all times",
            "Default" : false
        },
        {
            "Names" : "Priority",
            "Type" : NUMBER_TYPE,
            "Description" : "The priority order to load plugins - lowest first",
            "Default" : 100
        },
        {
            "Names" : "Name",
            "Type" : STRING_TYPE,
            "Description" : "The id of the plugin to install",
            "Mandatory" : true
        },
        {
            "Names" : "Source",
            "Description" : "Where the plugin for the plugin can be found",
            "Type" : STRING_TYPE,
            "Values" : [ "local", "git" ],
            "Mandatory" : true
        },
        {
            "Names" : "Source:git",
            "Children" : [
                {
                    "Names" : "Url",
                    "Description" : "The Url for the git repository",
                    "Type" : STRING_TYPE
                },
                {
                    "Names" : "Ref",
                    "Description" : "The ref to clone from the repo",
                    "Type" : STRING_TYPE,
                    "Default" : "main"
                },
                {
                    "Names" : "Path",
                    "Description" : "a path within in the repository where the plugin starts",
                    "Type" : STRING_TYPE,
                    "Default" : ""
                }
            ]
        }
    ]
/]
