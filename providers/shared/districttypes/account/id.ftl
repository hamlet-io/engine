[#ftl]

[@addDistrictType
    type=ACCOUNT_DISTRICT_TYPE
    properties=[
        {
            "Type"  : "Description",
            "Value" : "Account level solutions"
        }
    ]
    configuration={
        "Layers" : {
            "InstanceOrder" : [ TENANT_LAYER_TYPE, ACCOUNT_LAYER_TYPE ],
            "NamePartOrder" : [ "std" ],
            "NameParts" : {
                "std" : {
                    "Fixed" : "account"
                }
            }
        }
    }
/]
