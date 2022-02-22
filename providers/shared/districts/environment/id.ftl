[#ftl]

[@addDistrict
    type=ENVIRONMENT_DISTRICT_TYPE
    properties=[
        {
            "Type"  : "Description",
            "Value" : "Environment level solutions"
        }
    ]
    configuration={
        "Layers" : {
            "InstanceOrder" : [ TENANT_LAYER_TYPE, PRODUCT_LAYER_TYPE, ENVIRONMENT_LAYER_TYPE ],
            "NamePartOrder" : [ PRODUCT_LAYER_TYPE, ENVIRONMENT_LAYER_TYPE ]
        }
    }
/]
