[#ftl]

[@addExtendedAttributeSet
    type=IMAGE_URL_EXTENSION_ATTRIBUTESET_TYPE
    baseType=IMAGE_URL_ATTRIBUTESET_TYPE
    provider=SHARED_PROVIDER
    properties=[
        {
                "Type"  : "Description",
                "Value" : "An image that supports pulling the image from a URL and from an extension"
        }]
    attributes=[
        {
            "Names": "Source",
            "Values" : [
                "link",
                "registry",
                "url",
                "extension"
            ]
        },
        {
            "Names" : ["source:extension", "source:Extension"],
            "Description" : "Use an inline extension to set the content of the function",
            "Children" : [
                {
                    "Names" : "IncludeRunId",
                    "Description" : "Adds the RunId as a comment to ensure that it is unique",
                    "Types" : BOOLEAN_TYPE,
                    "Default" : true
                },
                {
                    "Names" : "CommentCharacters",
                    "Description" : "The single line comment sequence for your language",
                    "Types" : STRING_TYPE,
                    "Default" : '//'
                }
            ]
        }
    ]
/]
