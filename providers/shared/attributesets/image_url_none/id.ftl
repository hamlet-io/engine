[#ftl]

[@addExtendedAttributeSet
    type=IMAGE_URL_NONE_ATTRIBUTESET_TYPE
    baseType=IMAGE_URL_ATTRIBUTESET_TYPE
    provider=SHARED_PROVIDER
    properties=[
        {
                "Type"  : "Description",
                "Value" : "An image that supports pulling the image from a URL"
        }]
    attributes=[
        {
            "Names": "Source",
            "Values" : [
                "link",
                "registry",
                "url",
                "none"
            ]
        }
    ]
/]
