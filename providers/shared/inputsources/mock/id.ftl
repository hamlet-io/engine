[#ftl]

[@addInputSource
    id=MOCK_SHARED_INPUT_SOURCE
    description="Mocked input source"
/]

[@addStagesToInputSource
    inputSource=MOCK_SHARED_INPUT_SOURCE
    inputStages=[
        MASTERDATA_SHARED_INPUT_STAGE,
        MOCK_SHARED_INPUT_STAGE,
        CMDB_SHARED_INPUT_STAGE,
        QUALIFY_SHARED_INPUT_STAGE
    ]
/]