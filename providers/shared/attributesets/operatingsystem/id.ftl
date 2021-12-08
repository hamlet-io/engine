[#ftl]

[@addAttributeSet
    type=OPERATINGSYSTEM_ATTRIBUTESET_TYPE
    properties=[
        {
                "Type"  : "Description",
                "Value" : "Standard Configuration options to define an operating system"
        }]
    attributes=[
        {
            "Names" : "Architecture",
            "Description" : "The CPU Architecture used",
            "Types" : STRING_TYPE,
            "Values" : [ "i386", "x86_64", "arm64" ]
        },
        {
            "Names" : "Family",
            "Description" : "The broad family of operating system",
            "Types" : STRING_TYPE,
            "Values" : [ "linux", "windows", "macos" ]
        },
        {
            "Names" : "Distribution",
            "Description" : "The distribution of the operating system",
            "Types": STRING_TYPE
        },
        {
            "Names" : "MajorVersion",
            "Description" : "The major version of the distribution",
            "Types" : STRING_TYPE
        },
        {
            "Names" : "MinorVersion",
            "Description" : "The minor version of the distribution major version",
            "Types" : STRING_TYPE
        }
    ]
/]
