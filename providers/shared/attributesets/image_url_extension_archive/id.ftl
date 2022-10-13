[#ftl]

[@addExtendedAttributeSet
    type=IMAGE_URL_EXTENSION_ARCHIVE_ATTRIBUTESET_TYPE
    baseType=IMAGE_URL_EXTENSION_ATTRIBUTESET_TYPE
    provider=SHARED_PROVIDER
    properties=[
        {
                "Type"  : "Description",
                "Value" : "An image that supports pulling the image from a URL and from an extension and defining the Archive Format"
        }]
    attributes=[
        {
            "Names" : "ArchiveFormat",
            "Description" : "The archive format of the image to use",
            "Values" : [ "zip", "jar" ],
            "Types": STRING_TYPE,
            "Default" : "zip"
        }
    ]
/]
