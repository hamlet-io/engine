[#ftl]

[#-- Shared input stages --]

[#-- Command line options --]
[#assign COMMANDLINEOPTIONS_SHARED_INPUT_STAGE = "commandlineoptions"]

[#-- Provider specific data --]
[#assign MASTERDATA_SHARED_INPUT_STAGE = "masterdata"]

[#-- Fixed starting values --]
[#assign FIXTURE_SHARED_INPUT_STAGE = "fixture"]

[#-- Input from CMDB --]
[#assign CMDB_SHARED_INPUT_STAGE = "cmdb"]

[#-- Allow normalisation of data e.g. stack outputs from the cmdb --]
[#assign NORMALISE_SHARED_INPUT_STAGE = "normalise"]

[#-- Populate any missing data --]
[#assign SIMULATE_SHARED_INPUT_STAGE = "simulate"]

[#assign QUALIFY_SHARED_INPUT_STAGE = "qualify"]
