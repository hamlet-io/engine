[#ftl]

[@registerInputSource
    id=MOCK_SHARED_INPUT_SOURCE
    description="Mocked input source"
/]

[@addStagesToInputSource
    inputSource=MOCK_SHARED_INPUT_SOURCE
    inputStages=[
        MASTERDATA_SHARED_INPUT_STAGE,
        FIXTURE_SHARED_INPUT_STAGE,
        CMDB_SHARED_INPUT_STAGE,
        LAYERS_SHARED_INPUT_STAGE,
        PLUGINLOAD_SHARED_INPUT_STAGE,
        NORMALISE_SHARED_INPUT_STAGE,
        QUALIFY_SHARED_INPUT_STAGE
    ]
/]
