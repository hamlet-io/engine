[#ftl]

[@addInputSource
    id=COMPOSITE_SHARED_INPUT_SOURCE
    description="CMDB based input source"
/]

[@addStagesToInputSource
    inputSource=COMPOSITE_SHARED_INPUT_SOURCE
    inputStages=[
        MASTERDATA_SHARED_INPUT_STAGE,
        CMDB_SHARED_INPUT_STAGE,
        QUALIFY_SHARED_INPUT_STAGE
    ]
/]
