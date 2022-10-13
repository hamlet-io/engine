[#ftl]

[@addExtendedAttributeSet
    type=IMAGE_URL_ATTRIBUTESET_TYPE
    baseType=IMAGE_ATTRIBUTESET_TYPE
    provider=SHARED_PROVIDER
    properties=[
        {
                "Type"  : "Description",
                "Value" : "An image that supports pulling the image from a URL and supports disabling pulling an image"
        }]
    attributes=[
        {
            "Names": "Source",
            "Values" : [
                "link",
                "registry",
                "url"
            ]
        },
        {
            "Names" : [ "Source:url", "UrlSource" ],
            "Description" : "Url Source specific Configuration",
            "Children" : [
                {
                    "Names" : "Url",
                    "Description" : "The Url to the openapi file",
                    "Types" : STRING_TYPE
                },
                {
                    "Names" : "ImageHash",
                    "Description" : "The expected sha1 hash of the Url if empty any will be accepted",
                    "Types" : STRING_TYPE,
                    "Default" : ""
                }
            ]
        }
    ]
/]
