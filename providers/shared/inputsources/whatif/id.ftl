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
        LAYERS_SHARED_INPUT_STAGE,
        PLUGINLOAD_SHARED_INPUT_STAGE,
        NORMALISE_SHARED_INPUT_STAGE,
        SIMULATE_SHARED_INPUT_STAGE,
        QUALIFY_SHARED_INPUT_STAGE
    ]
/]
