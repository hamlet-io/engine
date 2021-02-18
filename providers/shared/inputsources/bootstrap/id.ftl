[#ftl]

[#--
No stages need to be added as the command line option stage
is all that is required and it is automatically added
included in every input source definition before any
explicit stages.
--]
[@addInputSource
    id=BOOTSTRAP_SHARED_INPUT_SOURCE
    description="Input source on startup"
/]

[#-- Ensure we have a minimal input source at startup --]
[@setInputSource BOOTSTRAP_SHARED_INPUT_SOURCE /]
[@setInputFilter {} /]