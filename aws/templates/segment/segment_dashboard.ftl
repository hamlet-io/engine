[#ftl]
[#macro segment_dashboard tier component]
    [#-- Dashboard --]
    [#if deploymentSubsetRequired("dashboard", true)]
        [@createDashboard
            mode=listMode
            id=formatSegmentCWDashboardId()
            name=formatSegmentFullName()
            components=dashboardComponents
        /]
    [/#if]
[/#macro]


