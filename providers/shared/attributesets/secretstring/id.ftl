[#ftl]

[@addAttributeSet
    type=SECRETSTRING_ATTRIBUTESET_TYPE
    properties=[
        {
                "Type"  : "Description",
                "Value" : "Defines the policy for generating secret strings"
        }
    ]
    attributes=[
        {
            "Names" : "MinLength",
            "Description" : "The minimum character length",
            "Types" : NUMBER_TYPE,
            "Default" : 20
        },
        {
            "Names" : "MaxLength",
            "Description" : "The maximum character length",
            "Types" : NUMBER_TYPE,
            "Default" : 30
        },
        {
            "Names" : "IncludeUpper",
            "Description" : "Include upper-case characters",
            "Types" : BOOLEAN_TYPE,
            "Default" : true
        },
        {
            "Names" : "IncludeLower",
            "Description" : "Include lower-case characters",
            "Types" : BOOLEAN_TYPE,
            "Default" : true
        },
        {
            "Names" : "IncludeSpecial",
            "Description" : "Include special characters",
            "Types" : BOOLEAN_TYPE,
            "Default" : false
        },
        {
            "Names" : "IncludeNumber",
            "Description" : "Include numbers characters",
            "Types" : BOOLEAN_TYPE,
            "Default": true
        },
        {
            "Names" : "ExcludedCharacters",
            "Description" : "Characters that must be excluded",
            "Types" : ARRAY_OF_STRING_TYPE,
            "Default" : [ r'"', r"'", r'$', r'@', r'/', r'\' ]
        },
        {
            "Names" : "RequireAllIncludedTypes",
            "Description" : "Require at least one of each included type",
            "Types" : BOOLEAN_TYPE,
            "Default" : true
        }
    ]
/]
