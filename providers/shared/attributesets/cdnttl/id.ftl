[#ftl]

[@addAttributeSet
    type=CDNTTL_ATTRIBUTESET_TYPE
    properties=[
        {
                "Type"  : "Description",
                "Value" : "Configuration for the cache TTL of a CDN"
        }]
    attributes=[
        {
            "Names" : "Default",
            "Description" : "The default cache time when the origin has not specified a time - seconds",
            "Types" : NUMBER_TYPE,
            "Default" : 600
        },
        {
            "Names" : "Maximum",
            "Description" : "The maximum time that an origin can specify to cache content - seconds",
            "Types" : NUMBER_TYPE,
            "Default" : 31536000
        },
        {
            "Names" : "Minimum",
            "Description" : "The minimum time that an origin can specify to cache content - seconds",
            "Types" : NUMBER_TYPE,
            "Default" : 0
        }
    ]
/]
