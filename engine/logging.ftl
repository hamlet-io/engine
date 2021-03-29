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
        [#list logLevelDescriptions as value]
            [#if value?has_content && level?lower_case == value ]
                [#assign currentLogLevel = value?index]
                [#break]
            [/#if]
        [/#list]
    [/#if]
    [#return getLogLevel()]
[/#function]

[#-- Set LogLevel variable to use a different log level --]
[#-- Can either be set as a number or as a string       --]
[#macro setLogLevel level]
    [#local level = updateLogLevel(level) ]
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

[#function willLog level ]
    [#return currentLogLevel <= level ]
[/#function]

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
        [#-- report whatever has been logged as the stop cause --]
        [#stop getJSON({"HamletMessages" : logMessages}) ]
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
