[#ftl]

[@addAttributeSet
    type=COMPUTEIMAGE_ATTRIBUTESET_TYPE
    properties=[
        {
                "Type"  : "Description",
                "Value" : "Configuration for the source of compute instance images"
        }]
    attributes=[
        {
            "Names" : "Source",
            "Description" : "Where to source the image id from - Reference: uses the Regions AMIs reference property to find the image",
            "Values" : [ "Reference" ],
            "Default" : "Reference"
        },
        {
            "Names" : "Source:Reference",
            "Children" : [
                {
                    "Names" : "OS",
                    "Description" : "The OS Image family defined in the Region AMI",
                    "Default" : "Centos"
                },
                {
                    "Names" : "Type",
                    "Description" : "The image Type defined under the family in the Region AMI",
                    "Default" : "EC2"
                }
            ]
        }
    ]
/]
