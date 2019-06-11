[#ftl]

[@addComponent
    type=EFS_COMPONENT_TYPE
    properties=
        [
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
        ]
/]

[@addComponentResourceGroup
    type=EFS_COMPONENT_TYPE
    attributes=
        [
            {
                "Names" : "Encrypted",
                "Type" : BOOLEAN_TYPE,
                "Default" : true
            },
            {
                "Names" : "Profiles",
                "Children" : profileChildConfiguration
            }
        ]
/]

[@addChildComponent
    type=EFS_MOUNT_COMPONENT_TYPE
    properties=
        [
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
        ]
    parent=EFS_COMPONENT_TYPE
    childAttribute="Mounts"
    linkAttributes="Mount"
/]

[@addComponentResourceGroup
    type=EFS_MOUNT_COMPONENT_TYPE
    attributes=
        [
            {
                "Names" : "Directory",
                "Type" : STRING_TYPE,
                "Mandatory" : true
            }
        ]
/]
