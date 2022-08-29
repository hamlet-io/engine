[#ftl]

[@addAttributeSet
    type=CERTIFICATE_ATTRIBUTESET_TYPE
    properties=[
        {
            "Type"  : "Description",
            "Value" : "Controls the full CN used for a certificate along with how the certificate should be generated"
        }
    ]
    attributes=[
        {
            "Names" : "Enabled",
            "Types" : BOOLEAN_TYPE,
            "Default" : true
        },
        {
            "Names" : "External",
            "Types" : BOOLEAN_TYPE
        },
        {
            "Names" : "Wildcard",
            "Types" : BOOLEAN_TYPE
        },
        {
            "AttributeSet" : DOMAINNAME_ATTRIBUTESET_TYPE
        },
        {
            "AttributeSet" : HOSTNAME_ATTRIBUTESET_TYPE
        }
    ]
/]
