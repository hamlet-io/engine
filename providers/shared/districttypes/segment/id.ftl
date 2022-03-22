[#ftl]

[@addDistrictType
    type=SEGMENT_DISTRICT_TYPE
    properties=[
        {
            "Type"  : "Description",
            "Value" : "Segment level solutions"
        }
    ]
    configuration={
        "Layers" : {
            "InstanceOrder" : [ TENANT_LAYER_TYPE, PRODUCT_LAYER_TYPE, ENVIRONMENT_LAYER_TYPE, SEGMENT_LAYER_TYPE ],
            "NamePartOrder" : [ PRODUCT_LAYER_TYPE, ENVIRONMENT_LAYER_TYPE, SEGMENT_LAYER_TYPE ],
            "NameParts" : {
                SEGMENT_LAYER_TYPE : {
                    "Ignore" : [ "default" ]
                }
            }
        }
    }
/]
