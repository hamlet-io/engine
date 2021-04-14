[#ftl]
[#include "/bootstrap.ftl" ]

[#-- Write a general message about this entrance invoke --]
[@writeStarterMessage
    writers=getCommandLineOptions().Logging.Writers
/]

[#-- Load the entrance to make sure that it is defined --]
[#-- Avoid the variable "entrance" to ensure the input --]
[#-- variable isn't overwritten                        --]
[#assign entranceType = getCLOEntranceType() ]
[#assign entranceEntry = getEntrance(entranceType) ]

[#-- Ensure any entrance specific input processing is performed before attempting to validate the inputs. --]
[@addEntranceInputSteps
    type=entranceType
/]

[#-- Validate Command line options are right for the entrance --]
[#assign validCommandLineOptions = getCompositeObject(entranceEntry.Configuration, getCommandLineOptions()) ]

[#-- Find and invoke the Entrance Macro --]
[#-- Entrances provided by explicit providers are preferred over the shared provider --]
[@invokeEntranceMacro
    type=entranceType
/]

[#-- Write generated logs out to loggers --]
[@writeLogs
    writers=getCommandLineOptions().Logging.Writers
/]
