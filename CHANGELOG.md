# Changelog

## Unreleased (2021-07-07)

#### New Features

* releaseinfo entrance
* define registries on the Account Layer
* typed full name
* subcomponent linking
* s3 flowlog expiration ([#1715](https://github.com/hamlet-io/engine/issues/1715))
* migrate testing to github workflows
* (template): add parameter extension macro ([#1701](https://github.com/hamlet-io/engine/issues/1701))
* input qualification ([#1695](https://github.com/hamlet-io/engine/issues/1695))
* add management port configuration to compute
* (ecs): extend placement strategy support
* set SES inbound active ruleset ([#1694](https://github.com/hamlet-io/engine/issues/1694))
* add support for packaging
* (dataset): adds support for image config
* (datapipeline): image source configuration
#### Fixes

* typos and refactorings
* occurrence cache
* default tagging
* (ci): default tag for images
* use workspace for engine dir
* storage profile volume configuration
* changelog generation
* align casing for bootstrap configuration
* (ci): add pull request trigger
* merge config from input seeders by default
* handle missing profiles
* typo in profile name
* getDomainObjects parameters
#### Refactorings

* remove context flow ([#1724](https://github.com/hamlet-io/engine/issues/1724))
* (ci): quality of life updates
* (ci): remove git and binaries from docker
* remove direct references to region ([#1716](https://github.com/hamlet-io/engine/issues/1716))
* add 1.15.1 of the wrapper ([#1719](https://github.com/hamlet-io/engine/issues/1719))
* (ci): updates from testing and ops
* only assemble settings in pregen
* set explicit typed profile attributes
* standardise profile lookups
* remove explicit qualification support ([#1696](https://github.com/hamlet-io/engine/issues/1696))

Full set of changes: [`8.1.2...5c32333`](https://github.com/hamlet-io/engine/compare/8.1.2...5c32333)

## 8.1.2 (2021-05-15)

#### New Features

* (contentnode): add support for image sources
* (mobileapp): add support for image config
* (adaptor): add attribute definition support
* (globaldb): define change stream support
* add compute task for system volumes
* write setting utility
* (apigateway): support for mutualTLS
* (computecluster): image source configuration
* openapi http endpoints and fragment
* yaml env support and alternatives
* yaml config output and contract properties
* add base permissions for ec2 components
* extend multipass generation support
* support executing multiple passes
* make refresh input state routine public ([#1669](https://github.com/hamlet-io/engine/issues/1669))
* (ecs): add compute provider support on service
* disable prefix for value extensions
* (healthcheck): update parameters from testing
* add healthcheck component definition
* warnings and deployed link failures
* compact log format for console
* add raw id and name formatting
* handle log based exceptions in engine
* include logging in entrance invoke
* add logging output processing
* add logging output writer
* console and log file writers
* additional output handlers for console logs
* extend output handler properties
* pretty output for json string
* include latest freemarker wrapper in engine
* add storage profile configuration ([#1642](https://github.com/hamlet-io/engine/issues/1642))
* compute image attribute sets
* add attribute extension support
* extendAttribute enhancements
* explicit extensions only
* computeTask configuration extension macro
* compute tasks
* add image configuration support for vms ([#1627](https://github.com/hamlet-io/engine/issues/1627))
* add attirbutes during extension processing ([#1625](https://github.com/hamlet-io/engine/issues/1625))
* (apigateway): image sourcing support ([#1622](https://github.com/hamlet-io/engine/issues/1622))
* (schema): add layers to the valid schema sections ([#1618](https://github.com/hamlet-io/engine/issues/1618))
* (cd): install the latest hamlet for testing
* adds mount path to volume config
* add support for engine output writing ([#1583](https://github.com/hamlet-io/engine/issues/1583))
* (sqs): ordering configuration for sqs queues
* validate deployment mode provided ([#1576](https://github.com/hamlet-io/engine/issues/1576))
* add occurrences entrance ([#1578](https://github.com/hamlet-io/engine/issues/1578))
* deployment state reporting ([#1574](https://github.com/hamlet-io/engine/issues/1574))
* (userpool): add schema attribute constraints ([#1564](https://github.com/hamlet-io/engine/issues/1564))
* ipaddressgroups on bastion component ([#1567](https://github.com/hamlet-io/engine/issues/1567))
* (gateway): add dpd action configuration
* Stop on fatal ([#1556](https://github.com/hamlet-io/engine/issues/1556))
* refactor input sources ([#1549](https://github.com/hamlet-io/engine/issues/1549))
* additional wrapper search options ([#1553](https://github.com/hamlet-io/engine/issues/1553))
* add schema generation for modules ([#1550](https://github.com/hamlet-io/engine/issues/1550))
* (jenkins): handle plugin upgrades ([#1543](https://github.com/hamlet-io/engine/issues/1543))
* whatif input provider ([#1538](https://github.com/hamlet-io/engine/issues/1538))
* add raw ids for occurrence details ([#1539](https://github.com/hamlet-io/engine/issues/1539))
* layerpath attributeset ([#1537](https://github.com/hamlet-io/engine/issues/1537))
* (baseline): add support for extensions on keys ([#1533](https://github.com/hamlet-io/engine/issues/1533))
* wrapper upgrade ([#1530](https://github.com/hamlet-io/engine/issues/1530))
* linkChildConfiguration to attributeSet attrs
* (s3): add support for inventory reports
* (spa): image source from url ([#1522](https://github.com/hamlet-io/engine/issues/1522))
* (userpool): authprovider extensions ([#1521](https://github.com/hamlet-io/engine/issues/1521))
* new task type: schemaset
* new schemaset view type
* (schema): new entrance type - schemaset
* add default schemacontract generation macro
* (externalnetwork): Alerting support ([#1515](https://github.com/hamlet-io/engine/issues/1515))
* (template): url image sourcing ([#1513](https://github.com/hamlet-io/engine/issues/1513))
* (s3): add s3vpcaccess extension
* changelog generation ([#1509](https://github.com/hamlet-io/engine/issues/1509))
* (registry): support for mutli region registry
* globaldb secondary indexes ([#1507](https://github.com/hamlet-io/engine/issues/1507))
* account inbound ses configuration
* MTA component
* (extensions): Allow mutliple extensions
* (extensions): support entrance extensions
* (extensions): convert existing fragments
* fragment migration to extensions
* allow setting encryption scheme for attributes
* (masterdata): add additional rabbitmq port definitions for queuehost
* (queuehost): initial definition
* (ecs): support container image sourcing ([#1495](https://github.com/hamlet-io/engine/issues/1495))
* (alerts): get metric dimensions from blueprint ([#1490](https://github.com/hamlet-io/engine/issues/1490))
* (secretstore): update configuration and make it shareable ([#1484](https://github.com/hamlet-io/engine/issues/1484))
* (network): flow log control
* (datafeed): add deployment specifc indludes to prefix
* (datafeed): deploy specifc prefixes
* bug-feature templates for issues
* manage one off instance failures
* os patching in solution config
* (lambda): pull images from external source ([#1456](https://github.com/hamlet-io/engine/issues/1456))
* add reference definitions for profiles
* define layers in shared provider
* Add engine support for layers
* (base): add object searching using a keys
* (ecs): add support for compute providers
* add scenario profile reference type
* add scenario loading through blueprint
* add operations and provider to mgmt
* (occurrence): Setting namespaces for occurrence
* (occurrence): support caching of occurrences
* (containers): ulimit configuration
* semver support ([#1434](https://github.com/hamlet-io/engine/issues/1434))
* (apigateway): added logstore attribute
* support for centralised service resources
* (ecs): placement constraint support
* template control per api gateway status
* Generic check for type in authentication header
* API gateway error format control
* hamlet info view
* s3 sync exclude support
* views for blueprint and schema
* dynamic model loading and scopes
* document set support
* add databucket replication attributes ([#1411](https://github.com/hamlet-io/engine/issues/1411))
* add support for token validity expressions ([#1409](https://github.com/hamlet-io/engine/issues/1409))
* (links): incl. support for case-insensitive link direction
* "Account" and fixed build scope ([#1402](https://github.com/hamlet-io/engine/issues/1402))
* add processor profiles
* add engine attr to containerhost
* splitting out container components
* (jenkins): add support for dind in hamlet agents
* (ecs): allow for fragment and image override in solution
* (ecs): add hostname macro for containers
* (ecs): fragment override and image override in solution
* aws ecs account settings
* management contract generation
* add deployment component attributes
* component deployment attributes
* deployment mode and group refernce
* set default deployment group for all components
* update format for deployment groups to incldue name/id
* support deployment document generation using group filters
* support deployment group filtering on occurrences
* (apigateway): add quota throttling
* (ecs): add healthcheck support
* (userpool): control oauth on clients
* (ecs): support for efs volume mounts on ecs tasks
* (efs): support chroot based on mount points
* (openapi): enable throttling settings on apigw
* add service role provisioing to account level
* add service role reference
* add policy to core component config
* (core): extend policy profiles to occurence level control
* (filetransfer): security policy control
* (filetransfer): support for a file transfer component with user integration
* (ecs): add lookup for ingress rules based on links for containers
* (waf): add waf logging profiles
* (schema): add required property to jsonschemas ([#1367](https://github.com/hamlet-io/engine/issues/1367))
* consolidate level clients in line with deployment groups
* add resource labels to support resourceSets in deployment groups
* add deployment groups for unit and level control
* (schema): added subsets for reference data and component schema
* (schema): default output - schema
* tier based network lookup ([#1359](https://github.com/hamlet-io/engine/issues/1359))
* (account): allow unique cmk aliases
* (console): add dedicated cmk option for console sessions
* (secretstore): new component type - secretstore
* set container level auth method for hamlet agent
* (externalservice): Networkacl support
* Container support for network profiles
* Network rule component configuration
* network profiles
* (s3): baseline s3 encryption permissions
* (s3): account level S3 Encryption
* (s3): add configuration support s3 Encryption
* (lb): WAF integration
* (ec2): volume encryption
* (console): Update console support for encryption
* (testcases): add additional output suffix types.
* (externalservice): Attributes for external service endpoint
* Bucket cleanup optional when copying files
* add host from network util
* (lb): add static endpoint forwarding
* (externalservice): add support for endpoints on an external service
* (gateway): destination port control
* (gateway): destination port control for private services
* (gateway): dns configuration support
* (lb): Network load balancer TLS offload
* (router): static route support
* (privateservice): intial support for private services ([#1330](https://github.com/hamlet-io/engine/issues/1330))
* (router): make BGP ASN mandatory
* (gateway): dynamic routing for private gw
* (gateway): private gateway
* (externalnetwork): intial external network support
* (gateway): support for the router component as an engine
* (router): adds initial support for the router component
* (globaldb): intial support for global dbs ([#1325](https://github.com/hamlet-io/engine/issues/1325))
* (fragment): startup command setting for agent
* (jenkins): add support for permanent ecs agents ([#1321](https://github.com/hamlet-io/engine/issues/1321))
* (apigateway): support gateway and cdn https profiles
* (mobileapp): OTA Support on CDN routes ([#1319](https://github.com/hamlet-io/engine/issues/1319))
* (userpool): Add Encryption schema to client secrets
#### Fixes

* syntax update for writing file for sync
* remove global settings assignement
* set deployment unit subset for template
* handle fileformat when not provided
* subset and alternative fixes
* update seeding order
* region in filenames ([#1667](https://github.com/hamlet-io/engine/issues/1667))
* typo in description
* minor spelling mistake fixes
* dynamic cmdb loading ([#1663](https://github.com/hamlet-io/engine/issues/1663))
* set multiAZ flag for blueprint generation ([#1662](https://github.com/hamlet-io/engine/issues/1662))
* typo in definition
* typo in definition
* log format message
* script store sync ([#1647](https://github.com/hamlet-io/engine/issues/1647))
* mta rule link attribute
* default storage profile name
* certificate behaviour configuration ([#1641](https://github.com/hamlet-io/engine/issues/1641))
* handle attribute formats in expand
* align alternative config with gen contract
* update state output to align with output
* pseudo stacks ([#1628](https://github.com/hamlet-io/engine/issues/1628))
* use loaded providers as definitive providers ([#1623](https://github.com/hamlet-io/engine/issues/1623))
* handle multiple load modules in module ([#1621](https://github.com/hamlet-io/engine/issues/1621))
* composite object wildcard handling ([#1614](https://github.com/hamlet-io/engine/issues/1614))
* loader module control ([#1620](https://github.com/hamlet-io/engine/issues/1620))
* line ending standard on unix
* line breaks in text output writing
* url references in changelog
* current unit detection
* handle deployment details in output file name
* correct spelling of output type
* output naming for deployment group prefix ([#1606](https://github.com/hamlet-io/engine/issues/1606))
* typo in blueprint generation
* schema output return
* disable qualifier transformer
* shared test seeder
* shared fixture seeder
* isolate testing to only include local code ([#1594](https://github.com/hamlet-io/engine/issues/1594))
* update layer type for region
* deploymentGroup validation
* (sqs): typo in id details
* define deploymentgroups for schemas ([#1586](https://github.com/hamlet-io/engine/issues/1586))
* regression in unlist generation
* RawId and Name values for subcomponents ([#1585](https://github.com/hamlet-io/engine/issues/1585))
* handle empty deployment unit Ids unitlist
* handle missing product domain ([#1580](https://github.com/hamlet-io/engine/issues/1580))
* update hamlet cli test cmds ([#1575](https://github.com/hamlet-io/engine/issues/1575))
* domain assembly process ([#1573](https://github.com/hamlet-io/engine/issues/1573))
* domain zone configuration ([#1572](https://github.com/hamlet-io/engine/issues/1572))
* handling of log level lookup ([#1569](https://github.com/hamlet-io/engine/issues/1569))
* allow for loading provider input replacement
* internaltest component definition ([#1547](https://github.com/hamlet-io/engine/issues/1547))
* Links as subobjects ([#1545](https://github.com/hamlet-io/engine/issues/1545))
* freemarker wrapper write functions ([#1542](https://github.com/hamlet-io/engine/issues/1542))
* (account): update script store clone setup ([#1541](https://github.com/hamlet-io/engine/issues/1541))
* image url override for containerregistry ([#1534](https://github.com/hamlet-io/engine/issues/1534))
* flowlog configuration ([#1531](https://github.com/hamlet-io/engine/issues/1531))
* AttributeSet handling ([#1529](https://github.com/hamlet-io/engine/issues/1529))
* link attributeset in s3 inventory reports
* attributeset schema one per
* (schema): reference data as one schema per schema
* revert type updates ([#1520](https://github.com/hamlet-io/engine/issues/1520))
* corrected a missed composite object data type update ([#1519](https://github.com/hamlet-io/engine/issues/1519))
* (lambda): correct type for Fixed code version
* schema data type generation
* schema assignment of multiple data types
* changelog generation
* typo in function names
* support buckets without at rest encryption
* remove service linked role check for cmk
* handle missing output mappings for resources
* masterdata inclusion in blueprint
* dind hostname and image details ([#1503](https://github.com/hamlet-io/engine/issues/1503))
* erroneous bracket ([#1501](https://github.com/hamlet-io/engine/issues/1501))
* minor typos
* hanlde missing values for lambda
* support missing extension
* (extensions): use resolved alias id for lookups
* update for ProviderId migration
* (schema): metaparameters should not ref links
* (datafeed): update description
* (reference): deployment mode default hanlding
* layer attribute searching
* handling of account iam and lg subsets
* (console): allow for psuedo s3 buckets
* (accountlayer): fix console logging
* detect missing data volumes
* expand range of certificate behaviours
* possible certificate behaviour attributes
* (s3): renamed global var back to dataOffline ([#1452](https://github.com/hamlet-io/engine/issues/1452))
* include int and version in occurrence caching ([#1451](https://github.com/hamlet-io/engine/issues/1451))
* provide deployment unit to build settings
* typo in function name
* semver supports asterisk in range indicator ([#1438](https://github.com/hamlet-io/engine/issues/1438))
* parameter ordering for invokeViewMacro ([#1428](https://github.com/hamlet-io/engine/issues/1428))
* allow for undefined networkendpoints on a region ([#1427](https://github.com/hamlet-io/engine/issues/1427))
* determine a primary provider to use for views ([#1422](https://github.com/hamlet-io/engine/issues/1422))
* authorizer failure messages
* 403 status on authorizer failure
* case insensitive token validity expression
* setup contract outputs in resourceset ([#1419](https://github.com/hamlet-io/engine/issues/1419))
* better control over scope combination
* output to use arrays
* reinstate link casing changes
* move link target to context support template
* remove copy and paste error
* typo in component
* typos in entrances
* reinstate schema output type
* macro lookup processing array handling
* entrance params and log messages
* provider updates from testing
* engine updates from testing
* typo in openapi syntax ([#1410](https://github.com/hamlet-io/engine/issues/1410))
* syntax and variable name updates for build scopes ([#1403](https://github.com/hamlet-io/engine/issues/1403))
* Explicit mock API passthrough behaviour ([#1401](https://github.com/hamlet-io/engine/issues/1401))
* (ecs): reinstate deployment details ([#1400](https://github.com/hamlet-io/engine/issues/1400))
* (ecs): add fragment and instance back to container props ([#1399](https://github.com/hamlet-io/engine/issues/1399))
* remove legacy component properties
* moved engine type from containerServiceAtttributes to only exist on the ecs component
* corrected call to child component macro
* explicit auth disable for options
* align resource sets with latest deployment groups
* (fragment): hamlet agent properties mounts ([#1397](https://github.com/hamlet-io/engine/issues/1397))
* remove legacy naming for fragment
* typos in fragments
* (ecs): Volume drivers and support for control over volume engine
* Pregeneration output format ([#1395](https://github.com/hamlet-io/engine/issues/1395))
* Output type for pregeneration scripts ([#1394](https://github.com/hamlet-io/engine/issues/1394))
* handle no deploymentunit ([#1392](https://github.com/hamlet-io/engine/issues/1392))
* (apigateway): do not attempt eval if definitions full is null ([#1389](https://github.com/hamlet-io/engine/issues/1389))
* remove unused deployment group config
* remove networkacl policies from iam links ([#1386](https://github.com/hamlet-io/engine/issues/1386))
* (settings): evaluation preferences for setting namespaces
* (openapi): quota throttling only exists on a usage plan
* (efs): use children for ownership
* (mock): set a fixed runId for mock
* use all units by default on resource lables
* ensure service linked roles exist for volume encryption
* only apply basic deployment groups for shared provider
* comments on resource label definition
* If no CIDRs defined, getGroupCIDRs should return false
* (s3): adds migration for queue permissions config
* (externalservice): Apply solution config on the resource group
* (networkProfile): enable or disable egress rules ([#1351](https://github.com/hamlet-io/engine/issues/1351))
* (masterdata): add global outbound rule description
* add settings back in to bootstraps
* remove console only support in bastion
* (account): only run cmk checks in specific units
* (bastion): allow ssh when internet access disabled
* (externalservice): fix var name for ip listing
* (externalservice): var name
* (externalservice): attribute name
* host filtering for networks
* (router): bgp asn description
* perfect square calculation
* use perfect squares for subnet calculations
* Wrapper fix for CMDB file system
* (fragment): agent override for aws user
* Subcomponent config on instance/version
* (gateway): remove mandatory requirement on Endpoint details
* Remove auth provider defaults ([#1313](https://github.com/hamlet-io/engine/issues/1313))
* Add dummy end.ftl for accounts composite
#### Refactorings

* state refresh trigger
* make task generic
* move alert config into attribute set
* update existing writer handlers
* use compute image source components
* remove wait for signal on autoscaling
* split attribute expansion in composite
* add scopes for compute tasks extensions
* align bootstrap naming with computetask
* composite template inclusion ([#1613](https://github.com/hamlet-io/engine/issues/1613))
* remove startup scripts from masterdata
* run tests first for feedback
* state processing ([#1605](https://github.com/hamlet-io/engine/issues/1605))
* CLO accessor names
* command line and masterdata processing
* remove metric setup from core ([#1582](https://github.com/hamlet-io/engine/issues/1582))
* change timing log level ([#1571](https://github.com/hamlet-io/engine/issues/1571))
* move github templates to org ([#1557](https://github.com/hamlet-io/engine/issues/1557))
* attributesets to be def on comp obj
* remove unused global vars
* add error handling for invalid schema instance
* (schemaset): align task attributes ([#1523](https://github.com/hamlet-io/engine/issues/1523))
* remove validation of multiple "type" variations.
* composite object model consistency with types
* identified type-less composite object attributes
* schema output macro to set definitions as object type
* schema macros/functions to handle a subsection
* limit usage of extension
* use name for url images
* move extension macros into shared
* (extensions): migrate existing fragments
* move extension support macros
* support components with mixed case names
* (network): rename flow action
* rename scenarios to modules
* setContext using layers
* move reference data loading to bootstrap
* load all reference data from blueprint
* change loading order for some templates
* switch COT to Hamlet ([#1413](https://github.com/hamlet-io/engine/issues/1413))
* model flow replacement
* remove models in favour of flows
* update view to support entrances
* rename scopes to flows
* update invoking services to entrances
* rename document sets to entrances
* remove dedicated entrypoints
* dynamic loading of subset marcos
* support for new deployment unit attr
* update structure of throttling configuration
* rename start to align with docker docs
* (cmk): service linked role check
* remove copy and paste vars
* add service imports in account templates
* Namespace matching support
#### Docs

* overhaul and revision of outdated readme ([#1566](https://github.com/hamlet-io/engine/issues/1566))
* Add basic README for shared extensions ([#1554](https://github.com/hamlet-io/engine/issues/1554))
#### Others

* changelog update
* (deps): bump lodash from 4.17.20 to 4.17.21 ([#1682](https://github.com/hamlet-io/engine/issues/1682))
* (deps): bump handlebars from 4.7.6 to 4.7.7 ([#1680](https://github.com/hamlet-io/engine/issues/1680))
* (deps): bump hosted-git-info from 2.8.8 to 2.8.9 ([#1681](https://github.com/hamlet-io/engine/issues/1681))
* add node 14 support for lambda ([#1638](https://github.com/hamlet-io/engine/issues/1638))
* (schemas): add layer schemas to schemaset ([#1633](https://github.com/hamlet-io/engine/issues/1633))
* release notes
* changelog
* changelog
* (spelling): updated spelling
