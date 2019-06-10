[#ftl]
[#macro aws_dashboard_cf_segment occurrence ]

    [#if deploymentSubsetRequired("genplan", false)]
        [@cfScript
            mode=listMode
            content=
                getGenerationPlan(["template"])
        /]
        [#return]
    [/#if]

    [@cfDebug listMode occurrence false /]

    [#if deploymentSubsetRequired("dashboard", true)]
        [@createDashboard
            mode=listMode
            id=formatSegmentCWDashboardId()
            name=formatSegmentFullName()
            components=dashboardComponents
        /]
    [/#if]
[/#macro]


