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
                "Type" : STRING_TYPE,
                "Mandatory" : true
            },
            {
                "Names" : [ "Extensions", "Fragment", "Container" ],
                "Description" : "Extensions to invoke as part of component processing",
                "Type" : ARRAY_OF_STRING_TYPE,
                "Default" : []
            },
            {
                "Names" : "Parameters",
                "Subobjects" : true,
                "Children" : [
                    {
                        "Names" : "Key",
                        "Type" : STRING_TYPE,
                        "Mandatory" : true
                    },
                    {
                        "Names" : "Value",
                        "Type" : STRING_TYPE
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
                        "Type" : STRING_TYPE,
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
                        "Type" : STRING_TYPE,
                        "Mandatory" : true
                    }
                ]
            },
            {
                "Names" : "NetworkAccess",
                "Type" : BOOLEAN_TYPE,
                "Default" : false
            },
            {
                "Names" : "Links",
                "Subobjects" : true,
                "Children" : linkChildrenConfiguration
            }
        ]
/]
