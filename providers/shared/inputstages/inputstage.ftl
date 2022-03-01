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

[#-- Layers (precursor to plugins) --]
[#assign LAYER_SHARED_INPUT_STAGE = "layer"]

[#-- Plugins - if any not already loaded, restart input processing  --]
[#assign PLUGIN_SHARED_INPUT_STAGE = "plugin"]

[#-- Modules - they shouldn't affect layers  --]
[#assign MODULE_SHARED_INPUT_STAGE = "module"]

[#-- Allow normalisation of data                        --]
[#-- - blueprint etc to include module provided content --]
[#-- - stack outputs from the cmdb                      --]
[#assign NORMALISE_SHARED_INPUT_STAGE = "normalise"]

[#-- Populate any missing data                                --]
[#-- Mainly for state where we want to pretend all components --]
[#-- have been deployed                                       --]
[#assign SIMULATE_SHARED_INPUT_STAGE = "simulate"]

[#assign QUALIFY_SHARED_INPUT_STAGE = "qualify"]

[#assign NULLCLEAN_SHARED_INPUT_STAGE = "nullclean"]
