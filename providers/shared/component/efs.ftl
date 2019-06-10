[#ftl]

[#assign componentConfiguration +=
    {
        EFS_COMPONENT_TYPE  : {
            "Properties" : [
                {
                    "Type" : "Description",
                    "Value" : "A managed network attached file share"
                },
                {
                    "Type" : "Providers",
                    "Value" : [ "aws" ]
                },
                {
                    "Type" : "ComponentLevel",
                    "Value" : "solution"
                }
            ],
            "Attributes" : [
                {
                    "Names" : "Encrypted",
                    "Type" : BOOLEAN_TYPE,
                    "Default" : true
                },
                {
                    "Names" : "Profiles",
                    "Children" : profileChildConfiguration
                }
            ],
            "Components" : [
                {
                    "Type" : EFS_MOUNT_COMPONENT_TYPE,
                    "Component" : "Mounts",
                    "Link" : "Mount"
                }
            ]
        },
        EFS_MOUNT_COMPONENT_TYPE : {
            "Properties" : [
                {
                    "Type" : "Description",
                    "Value" : "A specific directory on the share for OS mounting"
                },
                {
                    "Type" : "Providers",
                    "Value" : [ "aws" ]
                },
                {
                    "Type" : "ComponentLevel",
                    "Value" : "solution"
                }
            ],
            "Attributes" : [
                {
                    "Names" : "Directory",
                    "Type" : STRING_TYPE,
                    "Mandatory" : true
                }
            ]
        }
    }]
