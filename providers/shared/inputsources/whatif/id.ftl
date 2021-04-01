[#ftl]

[@registerInputSource
    id=WHATIF_SHARED_INPUT_SOURCE
    description="CMDB based input source with simulated stack outputs if undefined"
/]

[@addStagesToInputSource
    inputSource=WHATIF_SHARED_INPUT_SOURCE
    inputStages=[
        MASTERDATA_SHARED_INPUT_STAGE,
        CMDB_SHARED_INPUT_STAGE,
        LAYER_SHARED_INPUT_STAGE,
        PLUGIN_SHARED_INPUT_STAGE,
        MODULE_SHARED_INPUT_STAGE,
        NORMALISE_SHARED_INPUT_STAGE,
        SIMULATE_SHARED_INPUT_STAGE,
        QUALIFY_SHARED_INPUT_STAGE
    ]
/]