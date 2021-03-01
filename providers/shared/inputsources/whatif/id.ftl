[#ftl]

[@addInputSource
    id=WHATIF_SHARED_INPUT_SOURCE
    description="CMDB based input source with simulated stack outputs if undefined"
/]

[@addStagesToInputSource
    inputSource=WHATIF_SHARED_INPUT_SOURCE
    inputStages=[
        MASTERDATA_SHARED_INPUT_STAGE,
        MOCK_SHARED_INPUT_STAGE,
        CMDB_SHARED_INPUT_STAGE,
        SIMULATE_SHARED_INPUT_STAGE
    ]
/]