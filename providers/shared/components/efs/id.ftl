[#ftl]

[@addComponentDeployment
    type=EFS_COMPONENT_TYPE
    defaultGroup="solution"
    defaultPriority=50
/]

[@addComponent
    type=EFS_COMPONENT_TYPE
    properties=
        [
            {
                "Type" : "Description",
                "Value" : "A managed network attached file share"
            }
        ]
    attributes=
        [
            {
                "Names" : "Encrypted",
                "Types" : BOOLEAN_TYPE,
                "Default" : true
            },
            {
                "Names" : "Profiles",
                "Children" : [
                    {
                        "Names" : "Network",
                        "Types" : STRING_TYPE,
                        "Default" : "default"
                    }
                ]
            },
            {
                "Names" : "IPAddressGroups",
                "Types" : ARRAY_OF_STRING_TYPE,
                "Default" : [ "_localnet" ]
            },
            {
                "Names" : "Links",
                "Subobjects" : true,
                "AttributeSet" : LINK_ATTRIBUTESET_TYPE
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
            }
        ]
    attributes=
        [
            {
                "Names" : "Directory",
                "Types" : STRING_TYPE,
                "Mandatory" : true
            },
            {
                "Names" : "chroot",
                "Description" : "Set this directory as the root for clients who connect to it",
                "Types" : BOOLEAN_TYPE,
                "Default" : false
            },
            {
                "Names" : "Ownership",
                "Description" : "Defines the ownerships of files created under this directory",
                "Children" : [
                    {
                        "Names" : "Enforced",
                        "Description" : "Enforce these ownership details on all files",
                        "Types" : BOOLEAN_TYPE,
                        "Default" : false
                    },
                    {
                        "Names" : "UID",
                        "Description" : "The UID which owns the files",
                        "Types" : NUMBER_TYPE,
                        "Default" : ""
                    },
                    {
                        "Names" : "GID",
                        "Description" : "The GID which owns the files",
                        "Types" : NUMBER_TYPE,
                        "Default" : ""
                    },
                    {
                        "Names" : "SecondaryGIDS",
                        "Description" : "Secondary GIDS to apply to file ownership",
                        "Types" : ARRAY_OF_NUMBER_TYPE,
                        "Default" : []
                    },
                    {
                        "Names" : "Permissions",
                        "Description" : "The unix file permissions ( in number format) to apply",
                        "Types" : NUMBER_TYPE,
                        "Default" : 755
                    }
                ]
            }
        ]
    parent=EFS_COMPONENT_TYPE
    childAttribute="Mounts"
    linkAttributes="Mount"
/]
