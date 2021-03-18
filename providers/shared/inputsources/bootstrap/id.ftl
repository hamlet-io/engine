[#ftl]

[#--
No stages need to be added as the command line option stage
is all that is required and it is automatically
included in every input source definition before any
explicit stages.
--]
[@registerInputSource
    id=BOOTSTRAP_SHARED_INPUT_SOURCE
    description="Input source on startup"
/]

[#-- Now the bootstrap is known, use it to kick start the input system --]
[@initialiseInputProcessing
    inputSource=BOOTSTRAP_SHARED_INPUT_SOURCE
    inputFilter={}
/]
