[#ftl]

[@registerInputSource
    id=COMPOSITE_SHARED_INPUT_SOURCE
    description="CMDB based input source"
/]

[@addStagesToInputSource
    inputSource=COMPOSITE_SHARED_INPUT_SOURCE
    inputStages=[
        MASTERDATA_SHARED_INPUT_STAGE,
        CMDB_SHARED_INPUT_STAGE,
        NULLCLEAN_SHARED_INPUT_STAGE,
        LAYER_SHARED_INPUT_STAGE,
        PLUGIN_SHARED_INPUT_STAGE,
        MODULE_SHARED_INPUT_STAGE,
        NORMALISE_SHARED_INPUT_STAGE,
        QUALIFY_SHARED_INPUT_STAGE
    ]
/]
