[#ftl]

[@addDistrict
    type=ACCOUNT_DISTRICT_TYPE
    properties=[
        {
            "Type"  : "Description",
            "Value" : "Account level solutions"
        }
    ]
    layers={
        "InstanceOrder" : [ TENANT_LAYER_TYPE, ACCOUNT_LAYER_TYPE ],
        "NamePartOrder" : [ "std" ],
        "NameParts" : {
            "std" : {
                "Fixed" : "account"
            }
        }
    }
/]
