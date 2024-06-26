[#ftl]

[@addComponent
    type=ADAPTOR_COMPONENT_TYPE
    properties=
        [
            {
                "Type"  : "Description",
                "Value" : "A generic deployment process for non standard components provides a full context along with an occurrence that can be used for developing apis"
            },
            {
                "Type" : "Providers",
                "Value" : [ "aws" ]
            },
            {
                "Type" : "ComponentLevel",
                "Value" : "application"
            }
        ]
    attributes=
        [
            {
                "Names" : [ "Extensions", "Fragment", "Container" ],
                "Description" : "Extensions to invoke as part of component processing",
                "Types" : ARRAY_OF_STRING_TYPE,
                "Default" : []
            },
            {
                "Names" : "Links",
                "SubObjects" : true,
                "AttributeSet" : LINK_ATTRIBUTESET_TYPE
            },
            {
                "Names" : "Environment",
                "AttributeSet" : ENVIRONMENTFORMAT_ATTRIBUTESET_TYPE
            },
            {
                "Names" : "Image",
                "Description" : "Control the source of the image for the adaptor scripts",
                "AttributeSet" : IMAGE_URL_NONE_ATTRIBUTESET_TYPE
            },
            {
                "Names" : "Attributes",
                "Description" : "Define attributes that should be included in the adaptor state",
                "SubObjects" : true,
                "Children" : [
                    {
                        "Names" : "OutputAttributeType",
                        "Description" : "The output type to map the attribute to",
                        "Values" : [
                            ARN_ATTRIBUTE_TYPE,
                            URL_ATTRIBUTE_TYPE,
                            DNS_ATTRIBUTE_TYPE,
                            NAME_ATTRIBUTE_TYPE,
                            IP_ADDRESS_ATTRIBUTE_TYPE,
                            ALLOCATION_ATTRIBUTE_TYPE,
                            CANONICAL_ID_ATTRIBUTE_TYPE,
                            CERTIFICATE_ATTRIBUTE_TYPE,
                            KEY_ATTRIBUTE_TYPE,
                            QUALIFIER_ATTRIBUTE_TYPE,
                            ROOT_ATTRIBUTE_TYPE,
                            PORT_ATTRIBUTE_TYPE,
                            USERNAME_ATTRIBUTE_TYPE,
                            PASSWORD_ATTRIBUTE_TYPE,
                            GENERATEDPASSWORD_ATTRIBUTE_TYPE,
                            DATABASENAME_ATTRIBUTE_TYPE,
                            TOPICNAME_ATTRIBUTE_TYPE,
                            REPOSITORY_ATTRIBUTE_TYPE,
                            BRANCH_ATTRIBUTE_TYPE,
                            PREFIX_ATTRIBUTE_TYPE,
                            LASTRESTORE_ATTRIBUTE_TYPE,
                            REGION_ATTRIBUTE_TYPE,
                            EVENTSTREAM_ATTRIBUTE_TYPE,
                            SECRET_ATTRIBUTE_TYPE,
                            RESULT_ATTRIBUTE_TYPE
                        ],
                        "Types" : STRING_TYPE,
                        "Mandatory" : true
                    }
                ]
            },
            {
                "Names" : "Alerts",
                "Description": "Custom namespace alerts deployed as part of the adaptor",
                "SubObjects" : true,
                "AttributeSet" : ALERT_ATTRIBUTESET_TYPE
            },
            {
                "Names" : "Profiles",
                "Children" : [
                    {
                        "Names" : "Alert",
                        "Types" : STRING_TYPE,
                        "Default" : "default"
                    }
                ]
            }
        ]
/]

[@addComponentDeployment
    type=ADAPTOR_COMPONENT_TYPE
    defaultGroup="application"
/]
