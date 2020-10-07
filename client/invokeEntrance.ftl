[#ftl]
[#include "/bootstrap.ftl" ]

[#-- Load the entrance to make sure that it is defined --]
[#assign entranceType = commandLineOptions.Entrance.Type ]
[#assign entrance = getEntrance(entranceType) ]

[#-- Validate Command line options are right for the document set --]
[#assign validCommandLineOptions = getCompositeObject(entrance.Configuration, commandLineOptions) ]

[#-- Find and invoke the Entrance Macro --]
[#-- Entrances provided by explicit providers are preferred over the shared provider --]
[@invokeEntranceMacro
    entranceType=entranceType
/]
