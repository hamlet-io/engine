[#ftl]

[@addAttributeSet
    type=IMAGE_ATTRIBUTESET_TYPE
    properties=[
        {
            "Type"  : "Description",
            "Value" : "Controls where a code image is sourced from for an application component"
        }]
    attributes=[
        {
            "Names": "Source",
            "Description": "The type of source to use for the image",
            "Types": STRING_TYPE,
            "Values": [
                "link",
                "registry"
            ],
            "Default": "registry"
        },
        {
            "Names": "Link",
            "AttributeSet": LINK_ATTRIBUTESET_TYPE
        }
    ]
/]
