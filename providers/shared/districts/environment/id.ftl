[#ftl]

[@addDistrict
    type=ENVIRONMENT_DISTRICT_TYPE
    properties=[
        {
            "Type"  : "Description",
            "Value" : "Environment level solutions"
        }
    ]
    layers={
        "InstanceOrder" : [ TENANT_LAYER_TYPE, PRODUCT_LAYER_TYPE, ENVIRONMENT_LAYER_TYPE ],
        "NameOrder" : [ PRODUCT_LAYER_TYPE, ENVIRONMENT_LAYER_TYPE ]
    }
/]
