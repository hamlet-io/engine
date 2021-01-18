[#ftl]

[@addComponentDeployment
    type=TEMPLATE_COMPONENT_TYPE
    defaultGroup="application"
/]

[@addComponent
    type=TEMPLATE_COMPONENT_TYPE
    properties=
        [
            {
                "Type"  : "Description",
                "Value" : "Deploy a declarative template of resources"
            }
        ]
    attributes=
        [
            {
                "Names" : "RootFile",
                "Description" : "The name of the root template file in the build aretefact",
                "Types" : STRING_TYPE,
                "Mandatory" : true
            },
            {
                "Names" : [ "Extensions", "Fragment", "Container" ],
                "Description" : "Extensions to invoke as part of component processing",
                "Types" : ARRAY_OF_STRING_TYPE,
                "Default" : []
            },
            {
                "Names" : "Parameters",
                "Subobjects" : true,
                "Children" : [
                    {
                        "Names" : "Key",
                        "Types" : STRING_TYPE,
                        "Mandatory" : true
                    },
                    {
                        "Names" : "Value",
                        "Types" : STRING_TYPE
                    }
                ]
            },
            {
                "Names" : "Attributes",
                "Subobjects" : true,
                "Children" : [
                    {
                        "Names" : "TemplateOutputKey",
                        "Description" : "The name of the template output you want to map to an attribte",
                        "Types" : STRING_TYPE,
                        "Mandatory" : true
                    },
                    {
                        "Names" : "AttributeType",
                        "Description" : "The output type to map the attribute with ",
                        "Values" : [
                            DNS_ATTRIBUTE_TYPE,
                            ARN_ATTRIBUTE_TYPE,
                            URL_ATTRIBUTE_TYPE,
                            NAME_ATTRIBUTE_TYPE,
                            IP_ADDRESS_ATTRIBUTE_TYPE,
                            KEY_ATTRIBUTE_TYPE,
                            PORT_ATTRIBUTE_TYPE,
                            USERNAME_ATTRIBUTE_TYPE,
                            PASSWORD_ATTRIBUTE_TYPE,
                            REGION_ATTRIBUTE_TYPE
                        ],
                        "Types" : STRING_TYPE,
                        "Mandatory" : true
                    }
                ]
            },
            {
                "Names" : "NetworkAccess",
                "Types" : BOOLEAN_TYPE,
                "Default" : false
            },
            {
                "Names" : "Links",
                "Subobjects" : true,
                "AttributeSet" : LINK_ATTRIBUTESET_TYPE
            },
            {
                "Names" : "Image",
                "Description" : "Control the source of the image that is used for the function",
                "Children" : [
                    {
                        "Names" : "Source",
                        "Description" : "The source of the image - registry is the hamlet registry",
                        "Types" : STRING_TYPE,
                        "Mandatory" : true,
                        "Values" : [ "registry", "url" ],
                        "Default" : "registry"
                    },
                    {
                        "Names" : "UrlSource",
                        "Description" : "Url Source specific Configuration",
                        "Children" : [
                            {
                                "Names" : "Url",
                                "Description" : "The Url to the lambda zip file",
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
            }
        ]
/]
