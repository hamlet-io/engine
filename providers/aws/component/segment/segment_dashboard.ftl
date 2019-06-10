[#ftl]
[#macro aws_dashboard_cf_segment occurrence ]

    [#if deploymentSubsetRequired("dashboard", true)]
        [@createDashboard
            mode=listMode
            id=formatSegmentCWDashboardId()
            name=formatSegmentFullName()
            components=dashboardComponents
        /]
    [/#if]
[/#macro]


