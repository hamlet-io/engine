[#ftl]

[#assign TENANT_LAYER_TYPE = "Tenant"]
[#assign TENANT_LAYER_REFERENCE_TYPE = "Tenants" ]

[#assign ACCOUNT_LAYER_TYPE = "Account" ]
[#assign ACCOUNT_LAYER_REFERENCE_TYPE = "Accounts" ]

[#assign PRODUCT_LAYER_TYPE = "Product" ]
[#assign PRODUCT_LAYER_REFERENCE_TYPE = "Products" ]

[#assign SOLUTION_LAYER_TYPE = "Solution" ]
[#assign SOLUTION_LAYER_REFERENCE_TYPE = "Solutions" ]

[#assign ENVIRONMENT_LAYER_TYPE = "Environment" ]
[#assign ENVIRONMENT_LAYER_REFERENCE_TYPE = "Environments" ]

[#assign SEGMENT_LAYER_TYPE = "Segment" ]
[#assign SEGMENT_LAYER_REFERENCE_TYPE = "Segments" ]

[#-- Reference Shared configuration --]
[#assign moduleReferenceConfiguration = [
        {
            "Names" : "Enabled",
            "Description" : "To enable loading the module in this profile",
            "Type" : BOOLEAN_TYPE,
            "Default" : true
        },
        {
            "Names" : "Provider",
            "Description" : "The provider name which offers the module",
            "Type" : STRING_TYPE,
            "Mandatory" : true
        },
        {
            "Names" : "Name",
            "Description" : "The name of the scneario to load",
            "Type" : STRING_TYPE,
            "Mandatory" : true
        },
        {
            "Names" : "Parameters",
            "Description" : "The parameter values to provide to the module",
            "Subobjects" : true,
            "Children" : [
                {
                    "Names" : "Key",
                    "Type" : STRING_TYPE,
                    "Description" : "The key of the parameter",
                    "Mandatory" : true
                },
                {
                    "Names" : "Value",
                    "Type" : ANY_TYPE,
                    "Description" : "The value of the parameter",
                    "Mandatory" : true
                }
            ]
        }
    ]
]
