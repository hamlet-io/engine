[#ftl]

[#-----------
-- Logging --
-------------]

[#assign DEBUG_LOG_LEVEL = 0]
[#assign TRACE_LOG_LEVEL = 1]
[#assign TIMING_LOG_LEVEL = 2]
[#assign INFORMATION_LOG_LEVEL = 3]
[#assign WARNING_LOG_LEVEL = 5]
[#assign ERROR_LOG_LEVEL = 7]
[#assign FATAL_LOG_LEVEL = 9]

[#assign logLevelDescriptions = [
    "debug",
    "trace",
    "timing",
    "info",
    "",
    "warn",
    "",
    "error",
    "",
    "fatal"
    ] ]

[#assign errorLogMinimumLevel = WARNING_LOG_LEVEL ]
[#assign fatalLogLevel        = FATAL_LOG_LEVEL ]

[#-- Log history during invocation of the engine --]
[#assign logMessages = [] ]

[#-- Default value ensures any startup message before   --]
[#-- any user log level setting is applied are captured --]
[#assign currentLogLevel = INFORMATION_LOG_LEVEL ]

[#-- Set the stop threshold                             --]
[#-- Number of fatal errors at which processing will    --]
[#-- be stopped                                         --]
[#-- <=0 ==> skip threshold checking                    --]
[#assign logFatalStopThreshold = 0]

[#-- Set the depth threshold                            --]
[#-- Limits the depth of objects logged                 --]
[#assign logMessageDepthLimit = 0]

[#function getLogLevel ]
    [#return currentLogLevel]
[/#function]

[#function updateLogLevel level]
    [#if level?is_number]
        [#assign currentLogLevel = level]
    [/#if]
    [#if level?is_string && level?has_content]
        [#assign currentLogLevel = getLogLevelFromDescription(level)]
    [/#if]
    [#return getLogLevel()]
[/#function]

[#-- Set LogLevel variable to use a different log level --]
[#-- Can either be set as a number or as a string       --]
[#macro setLogLevel level]
    [#local level = updateLogLevel(level) ]
[/#macro]

[#macro setFatalLogLevel level ]
    [#if level?is_number]
        [#assign fatalLogLevel = level]
    [/#if]
    [#if level?is_string && level?has_content]
        [#assign fatalLogLevel = getLogLevelFromDescription(level)]
    [/#if]
[/#macro]

[#-- Set LogLevel variable to use a different log level --]
[#-- Can either be set as a number or as a string       --]
[#macro setLogDepthLimit depth]
    [#local requiredDepth = depth]
    [#if depth?is_string]
        [#local requiredDepth = depth?number]
    [/#if]
    [#if requiredDepth?is_number && requiredDepth > 0]
        [#assign logMessageDepthLimit = requiredDepth ]
    [/#if]
[/#macro]

[#-- Level/Severity Handling --]
[#function getLogLevelFromDescription severity ]
    [#if severity?is_number ]
        [#return severity]
    [/#if]
    [#if severity?is_string && severity?has_content]
        [#list logLevelDescriptions as value]
            [#if value?has_content && severity?lower_case == value ]
                [#return value?index ]
                [#break]
            [/#if]
        [/#list]
    [/#if]
    [#return 0]
[/#function]

[#function willLog level ]
    [#return currentLogLevel <= level ]
[/#function]

[#function isError level ]
    [#return errorLogMinimumLevel <= getLogLevelFromDescription(level) ]
[/#function]

[#function isFatal level ]
    [#return fatalLogLevel <= getLogLevelFromDescription(level) ]
[/#function]

[#-- Exit handling --]
[#-- Uses the generated logs to determine the exit status of the wrapper --]
[#macro setExitStatusFromLogs ]
    [#list logMessages as logMessage ]
        [#if fatalLogLevel <= getLogLevelFromDescription(logMessage.Severity) ]
            [#local result = setExitStatus("110")]
        [/#if]
    [/#list]
[/#macro]

[#-- Log Writing --]
[#-- These are our standard log content generators which use the output writer process to get logs to users --]
[#macro writeStarterMessage writers ]
    [#list getCommandLineOptions().Logging.Writers as writer ]

        [@setupOutput
            writer=writer
        /]

        [#if willLog(INFORMATION_LOG_LEVEL)]

            [#local content = [
                    "entrance: ${getCLOEntranceType()}",
                    "output: ${getCLODeploymentOutputType()}"
                ] +
                valueIfContent(
                    [ "subset: ${getCLODeploymentUnitSubset()}" ],
                    getCLODeploymentUnitSubset(),
                    []
                ) +
                valueIfContent(
                    [ "alternative: ${getCLODeploymentUnitAlternative()}" ],
                    getCLODeploymentUnitAlternative(),
                    []
                )]
            [@writeOutput
                content=content?join(" | ")?ensure_starts_with("[*] ")
                writer=writer
            /]
        [/#if]

    [/#list]
[/#macro]

[#macro writeLogs writers ]
    [#list getCommandLineOptions().Logging.Writers as writer ]

        [#-- Output a logfile of the log messages --]
        [@setupOutput
            writer=writer
        /]

        [#local logFormat = logMessages
                                ?map( x -> isFatal(x.Severity) || x.Severity == "debug" )
                                ?seq_contains(true)
                                ?then(
                                    "full",
                                    getCommandLineOptions().Logging.Format
                                )]

        [#switch getOutputProperties()["type"] ]

            [#case "console" ]

                [#if logMessages?has_content ]

                    [@writeOutput
                        content="\n Hamlet Engine Logs\n--------------------\n\n"
                        writer=writer
                    /]

                    [#list logMessages as logMessage ]
                        [#if isError( ((logLevelDescriptions?seq_index_of(logMessage.Level))!0) ) ]
                            [@setOutputProperties
                                properties={
                                    "type:console" : {
                                        "stream" : "stderr"
                                    }
                                }
                            /]
                        [#else]
                            [@setOutputProperties
                                properties={
                                    "type:console" : {
                                        "stream" : "stdout"
                                    }
                                }
                            /]
                        [/#if]

                        [#switch logFormat]
                            [#case "compact"]
                                [#local message = "- ${logMessage.Severity} - ${logMessage.Message}" ]
                                [@writeOutput
                                    content=message
                                    writer=writer
                                /]
                                [#break]

                            [#default]
                                [@writeOutput
                                    content=logMessage
                                    writer=writer
                                /]
                        [/#switch]
                    [/#list]

                    [@writeOutput
                        content="\n--------------------"
                        writer=writer
                    /]

                    [#local logNotes = [] ]

                    [#local logCounts = [] ]
                    [#list logLevelDescriptions as description ]
                        [#local logCount = logMessages?filter( log -> log.Severity == description )?size ]
                        [#if logCount > 0 ]
                            [#local logCounts += [ "${description} : ${logCount}" ] ]
                        [/#if]
                    [/#list]
                    [#local logNotes += [ logCounts?join(" | ") ]]

                    [#switch logFormat]
                        [#case "compact"]
                            [#local logNotes += [ "Compact log output format used set HAMLET_LOG_FORMAT=full for the complete details" ]]
                            [#break]

                    [/#switch]

                    [@writeOutput
                        content=(logNotes?map( x -> x?ensure_starts_with("[-] ")))?join("\n") + "\n\n"
                        writer=writer
                    /]

                [/#if]
                [#break]

            [#default]

                [@setOutputProperties
                    properties={
                        "type:file" : {
                            "format" : "json"
                        }
                    }
                /]

                [@writeOutput
                    content={ "HamletMessages" : logMessages }
                    writer=writer
                /]

        [/#switch]
    [/#list]
[/#macro]

[#-- Log Message Macros --]
[#macro logMessage severity message context={} detail={} enabled=false]
    [#if enabled && willLog(severity)]
        [#local entry =
            {
                "Timestamp" : datetimeAsString(.now),
                "Severity" : logLevelDescriptions[severity]!"unknown",
                "Message" : message
            } +
            attributeIfContent("Context", context) +
            attributeIfContent("Detail", detail)
        ]
        [#if logMessageDepthLimit > 0]
            [#-- Allow for the overall entry structure in the depth calculation --]
            [#local entry = getEntityToDepth(entry, logMessageDepthLimit + 1) ]
        [/#if]
        [#assign logMessages += [entry] ]
    [/#if]
[/#macro]

[#macro debug message context={} detail={} enabled=true]
    [@logMessage
        severity=DEBUG_LOG_LEVEL
        message=message
        context=context
        detail=detail
        enabled=enabled
    /]
[/#macro]

[#macro trace message context={} detail={} enabled=true]
    [@logMessage
        severity=TRACE_LOG_LEVEL
        message=message
        context=context
        detail=detail
        enabled=enabled
    /]
[/#macro]

[#macro info message context={} detail={} enabled=true]
    [@logMessage
        severity=INFORMATION_LOG_LEVEL
        message=message
        context=context
        detail=detail
        enabled=enabled
    /]
[/#macro]

[#macro timing message context={} detail={} enabled=true]
    [@logMessage
        severity=TIMING_LOG_LEVEL
        message=message
        context=context
        detail=detail
        enabled=enabled
    /]
[/#macro]

[#macro warn message context={} detail={} enabled=true]
    [@logMessage
        severity=WARNING_LOG_LEVEL
        message=message
        context=context
        detail=detail
        enabled=enabled
    /]
[/#macro]

[#macro error message context={} detail={} enabled=true]
    [@logMessage
        severity=ERROR_LOG_LEVEL
        message=message
        context=context
        detail=detail
        enabled=enabled
    /]
[/#macro]

[#assign logFatalMessageCount = 0]

[#macro fatal message context={} detail={} enabled=true stop=false]

    [@logMessage
        severity=FATAL_LOG_LEVEL
        message=message
        context=context
        detail=detail
        enabled=enabled
    /]

    [#-- one more fatal message seen --]
    [#assign logFatalMessageCount += 1]

    [#if stop ||
        ((logFatalStopThreshold > 0) && (logFatalMessageCount >= logFatalStopThreshold)) ]
        [#-- Before we stop log anything in the log messages - there should always been the fatal message --]
        [@writeLogs
            writers=getCommandLineOptions().Logging.Writers
        /]
        [#stop "hamlet fatal log" ]
    [/#if]
[/#macro]

[#macro setLogFatalStopThreshold threshold ]
    [#local logFatalStopThreshold = threshold ]
[/#macro]

[#macro precondition function context={} detail={} enabled=true]
    [@fatal
        message="Precondition failed for " + function
        context=context
        detail=detail
        enabled=enabled
    /]
[/#macro]

[#macro postcondition function context={} detail={} enabled=true]
    [@fatal
        message="Postcondition failed for " + function
        context=context
        detail=detail
        enabled=enabled
    /]
[/#macro]

[#-- In-line content logging --]
[#-- inline logs allow for creating logs as part of outputs --]
[#assign inlineLogLevels =
    {
        "HamletDebug:" : DEBUG_LOG_LEVEL,
        "HamletTrace:" : TRACE_LOG_LEVEL,
        "HamletTiming:" : TIMING_LOG_LEVEL,
        "HamletInfo:" : INFORMATION_LOG_LEVEL,
        "HamletWarning:" : WARNING_LOG_LEVEL,
        "HamletError:" : ERROR_LOG_LEVEL,
        "HamletFatal:" : FATAL_LOG_LEVEL
    }
]

[#function getInlineLogs content parent={} inlineLogs=[] ]
    [#if content?is_hash ]
        [#list content as key,value ]
            [#list inlineLogLevels as message, severity]
                [#if key?contains(message) ]
                    [#local inlineLogs += [ { "severity" : severity, "context" : content, "detail" : key }]]
                [/#if]
            [/#list]

            [#local inlineLogs = getInlineLogs(value, content, inlineLogs) ]
        [/#list]
    [/#if]

    [#if content?is_sequence ]
        [#list content as value ]
            [#local inlineLogs = getInlineLogs(value, content, inlineLogs)]
        [/#list]
    [/#if]

    [#if content?is_string ]
        [#list inlineLogLevels as message, severity]
            [#if content?contains(message)]
                [#local inlineLogs += [ { "severity" : severity, "context" : parent, "detail" : content }] ]
            [/#if]
        [/#list]
    [/#if]
    [#return inlineLogs]
[/#function]

[#macro inlineLogMessages content ]
    [#local inlineLogs = getInlineLogs(content)]
    [#list inlineLogs as inlineLog ]
        [@logMessage
            severity=inlineLog.severity
            message="In-line log message - see context for details"
            context=inlineLog.context
            detail=inlineLog.detail
            enabled=true
        /]
    [/#list]
[/#macro]
