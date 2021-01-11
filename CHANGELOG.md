# [0.0.0](https://github.com/hamlet-io/engine-plugin-aws/compare/v7.0.0...v0.0.0) (2021-01-11)


### Bug Fixes

* 403 status on authorizer failure ([9a25bd0](https://github.com/hamlet-io/engine-plugin-aws/commit/9a25bd0d41c9f0091c5accc9ba23f8f7b33f6634))
* Add dummy end.ftl for accounts composite ([51198a8](https://github.com/hamlet-io/engine-plugin-aws/commit/51198a8b4f638443e42521517d77bbda54a8038a))
* add settings back in to bootstraps ([2d29252](https://github.com/hamlet-io/engine-plugin-aws/commit/2d29252888df54db5259852fa3e1cd73c2be51ab))
* align resource sets with latest deployment groups ([24785c3](https://github.com/hamlet-io/engine-plugin-aws/commit/24785c368c3d3ef38427a6ec59a6003004be79df))
* allow for undefined networkendpoints on a region ([#1427](https://github.com/hamlet-io/engine-plugin-aws/issues/1427)) ([58a0342](https://github.com/hamlet-io/engine-plugin-aws/commit/58a0342aab86eb6d512df98490e9f10ed5b1f764))
* authorizer failure messages ([9e8a785](https://github.com/hamlet-io/engine-plugin-aws/commit/9e8a7856e2b027f67483917eb4ffdcfa8397bb0b))
* better control over scope combination ([34a8894](https://github.com/hamlet-io/engine-plugin-aws/commit/34a8894b4e3e01a5c91ef58df14748d04a84c4dd))
* case insensitive token validity expression ([58ace15](https://github.com/hamlet-io/engine-plugin-aws/commit/58ace154c7197b399d66ecb641a7317008595a1a))
* comments on resource label definition ([de2321f](https://github.com/hamlet-io/engine-plugin-aws/commit/de2321fd840eb0681c277709d373dd1017551560))
* corrected call to child component macro ([0bed2b0](https://github.com/hamlet-io/engine-plugin-aws/commit/0bed2b0d8b3e04a0ff48f9c39afaa27a930837e9))
* detect missing data volumes ([2b9177d](https://github.com/hamlet-io/engine-plugin-aws/commit/2b9177d1e43faeef1953c973c2bd5c975e2563c2))
* determine a primary provider to use for views ([#1422](https://github.com/hamlet-io/engine-plugin-aws/issues/1422)) ([6688a73](https://github.com/hamlet-io/engine-plugin-aws/commit/6688a73739a30b4d79ca9b7d9dc9b042c73862f4))
* dind hostname and image details ([#1503](https://github.com/hamlet-io/engine-plugin-aws/issues/1503)) ([d36e8ca](https://github.com/hamlet-io/engine-plugin-aws/commit/d36e8ca03968db4f9d936e727f0e5099a7b415f4))
* engine updates from testing ([69e5cc8](https://github.com/hamlet-io/engine-plugin-aws/commit/69e5cc8212dc7f7b44d6bdb7e3c9821ad3131cd8))
* ensure service linked roles exist for volume encryption ([d62765c](https://github.com/hamlet-io/engine-plugin-aws/commit/d62765c03cbd11877c13431b8c200467a6a26aee))
* entrance params and log messages ([bf1ac49](https://github.com/hamlet-io/engine-plugin-aws/commit/bf1ac49b5c354aa82e90b9ff044296b3fcd87a26))
* erroneous bracket ([#1501](https://github.com/hamlet-io/engine-plugin-aws/issues/1501)) ([8d0230f](https://github.com/hamlet-io/engine-plugin-aws/commit/8d0230f0c3f3fa317154682312945966e50c6f7c))
* expand range of certificate behaviours ([e4b4499](https://github.com/hamlet-io/engine-plugin-aws/commit/e4b4499f0241213031f983d59eb61adcd854a6d5))
* explicit auth disable for options ([778fff8](https://github.com/hamlet-io/engine-plugin-aws/commit/778fff8d5703cbd4588a38145cc7e167a933e175))
* Explicit mock API passthrough behaviour ([#1401](https://github.com/hamlet-io/engine-plugin-aws/issues/1401)) ([bfed07c](https://github.com/hamlet-io/engine-plugin-aws/commit/bfed07c398018f9d02563945ad93a964b18514cc))
* handle missing output mappings for resources ([2a70608](https://github.com/hamlet-io/engine-plugin-aws/commit/2a70608a74d2cda0b95873f56050bef12e8ac8ce))
* handle no deploymentunit ([#1392](https://github.com/hamlet-io/engine-plugin-aws/issues/1392)) ([6d0a51a](https://github.com/hamlet-io/engine-plugin-aws/commit/6d0a51ae11e1cb948f1ac827900913576befc530))
* hanlde missing values for lambda ([d53ddf8](https://github.com/hamlet-io/engine-plugin-aws/commit/d53ddf85f013342ba466685f0bf17104c54bf26e))
* host filtering for networks ([1a627a9](https://github.com/hamlet-io/engine-plugin-aws/commit/1a627a9c9a20245db4cf64737de7f4fcd69376f7))
* If no CIDRs defined, getGroupCIDRs should return false ([0a7344c](https://github.com/hamlet-io/engine-plugin-aws/commit/0a7344c581da0bdd89fdf050600e5c338c3ac75a))
* include int and version in occurrence caching ([#1451](https://github.com/hamlet-io/engine-plugin-aws/issues/1451)) ([833acee](https://github.com/hamlet-io/engine-plugin-aws/commit/833acee6b7af0af60ff1404a2971924cdfc5c413))
* layer attribute searching ([00bb41e](https://github.com/hamlet-io/engine-plugin-aws/commit/00bb41e44637cdbb659767ab1416e46c3bc4469d))
* macro lookup processing array handling ([1c09893](https://github.com/hamlet-io/engine-plugin-aws/commit/1c098937b63f538837392768d01fef57b5ad5fac))
* masterdata inclusion in blueprint ([f44df57](https://github.com/hamlet-io/engine-plugin-aws/commit/f44df5782e04b3e1386eaf67a0bcf6a630e5a3eb))
* minor typos ([539552c](https://github.com/hamlet-io/engine-plugin-aws/commit/539552c37dd07f41ec2d1a7103a89ade3d0dfa80))
* move link target to context support template ([f0ff218](https://github.com/hamlet-io/engine-plugin-aws/commit/f0ff21891a424ec4e7b0702c6d6e3bb2be8effd4))
* moved engine type from containerServiceAtttributes to only exist on the ecs component ([b94d16f](https://github.com/hamlet-io/engine-plugin-aws/commit/b94d16f587e4cdfd7a7d0bbacab963986d689b2c))
* only apply basic deployment groups for shared provider ([17a2df5](https://github.com/hamlet-io/engine-plugin-aws/commit/17a2df5a98d40f35f0154bd1999fba9da9ccf282))
* output to use arrays ([c94a46a](https://github.com/hamlet-io/engine-plugin-aws/commit/c94a46a5966ac84bfb20c602eef3321378200970))
* Output type for pregeneration scripts ([#1394](https://github.com/hamlet-io/engine-plugin-aws/issues/1394)) ([17def79](https://github.com/hamlet-io/engine-plugin-aws/commit/17def7993e34dd6bce9bfed75711335cbf1e5368))
* parameter ordering for invokeViewMacro ([#1428](https://github.com/hamlet-io/engine-plugin-aws/issues/1428)) ([3286440](https://github.com/hamlet-io/engine-plugin-aws/commit/32864408123f347f1853b3cdb4ba1ac162822ef8))
* perfect square calculation ([ae4b4d1](https://github.com/hamlet-io/engine-plugin-aws/commit/ae4b4d1c9a29b562889fded105dd3f8a3a2f3653))
* possible certificate behaviour attributes ([4fbb44a](https://github.com/hamlet-io/engine-plugin-aws/commit/4fbb44a4ce782a7490ba0aa6214df1b3ef4c0155))
* Pregeneration output format ([#1395](https://github.com/hamlet-io/engine-plugin-aws/issues/1395)) ([1638ad3](https://github.com/hamlet-io/engine-plugin-aws/commit/1638ad3f0e90394b1ed9d0998d98635d59c5984c))
* provide deployment unit to build settings ([d3215fe](https://github.com/hamlet-io/engine-plugin-aws/commit/d3215fe641b9e50906a1e2e013743bc78b495936))
* provider updates from testing ([060fa19](https://github.com/hamlet-io/engine-plugin-aws/commit/060fa190dc78df1c6545b2e6a41183e98edb5f99))
* reinstate link casing changes ([82f390e](https://github.com/hamlet-io/engine-plugin-aws/commit/82f390ed59cb1d15be8e69d070d15693dd7a35ca))
* reinstate schema output type ([9220a45](https://github.com/hamlet-io/engine-plugin-aws/commit/9220a452d18f9d1ab1b573ce52f48c26834a7d45))
* Remove auth provider defaults ([#1313](https://github.com/hamlet-io/engine-plugin-aws/issues/1313)) ([1a726c1](https://github.com/hamlet-io/engine-plugin-aws/commit/1a726c159cc63125f2c6a1c276bbcbff3fe83b7f))
* remove console only support in bastion ([55272ff](https://github.com/hamlet-io/engine-plugin-aws/commit/55272ffbfc71067fb0d3f171042f24d2308b0ced))
* remove copy and paste error ([71998ed](https://github.com/hamlet-io/engine-plugin-aws/commit/71998ed19db99c687a02a281d6f3af4369fd005d))
* remove legacy component properties ([a795555](https://github.com/hamlet-io/engine-plugin-aws/commit/a79555509ac405f40b91a2d463dd11462dff13b1))
* remove legacy naming for fragment ([0d606ee](https://github.com/hamlet-io/engine-plugin-aws/commit/0d606ee0d3676ea70f1059b2fbc12ab5579889ae))
* remove networkacl policies from iam links ([#1386](https://github.com/hamlet-io/engine-plugin-aws/issues/1386)) ([9f38808](https://github.com/hamlet-io/engine-plugin-aws/commit/9f388084b235b6d9d18a619c29e283bfd6d64987))
* remove service linked role check for cmk ([79ea4b8](https://github.com/hamlet-io/engine-plugin-aws/commit/79ea4b8986ee43fd7da27ad620251d58336df69a))
* remove unused deployment group config ([d2338df](https://github.com/hamlet-io/engine-plugin-aws/commit/d2338dfa6797eed906b6bfc627605a7703fa7905))
* semver supports asterisk in range indicator ([#1438](https://github.com/hamlet-io/engine-plugin-aws/issues/1438)) ([8b11697](https://github.com/hamlet-io/engine-plugin-aws/commit/8b1169739fedab02843cfdbb868071af64e8e3bc))
* setup contract outputs in resourceset ([#1419](https://github.com/hamlet-io/engine-plugin-aws/issues/1419)) ([12eed31](https://github.com/hamlet-io/engine-plugin-aws/commit/12eed31d1335f793463538c13f0ec1d466bd7522))
* Subcomponent config on instance/version ([2ea633e](https://github.com/hamlet-io/engine-plugin-aws/commit/2ea633e89653e92c0e5cb504b19ae837942673cb))
* support buckets without at rest encryption ([534b56a](https://github.com/hamlet-io/engine-plugin-aws/commit/534b56a1bf987dd64b90dfc4a375b5b6d3a8650a))
* support missing extension ([0c951a4](https://github.com/hamlet-io/engine-plugin-aws/commit/0c951a4a6cc8882e157be8cf617f6bb8dc401038))
* syntax and variable name updates for build scopes ([#1403](https://github.com/hamlet-io/engine-plugin-aws/issues/1403)) ([389630f](https://github.com/hamlet-io/engine-plugin-aws/commit/389630fdb97e84e673e335b2962fea21d17204ce))
* typo in component ([d82c2fb](https://github.com/hamlet-io/engine-plugin-aws/commit/d82c2fb6d1981a436cb82bf2fd2b6cfce1bbf4e5))
* typo in function name ([2d4d4d6](https://github.com/hamlet-io/engine-plugin-aws/commit/2d4d4d61ddfcfb5d7e042c3806c46c020e2bbf09))
* typo in function names ([2513731](https://github.com/hamlet-io/engine-plugin-aws/commit/2513731122d9e9dd3e10ad2976f798ece285eb03))
* typo in openapi syntax ([#1410](https://github.com/hamlet-io/engine-plugin-aws/issues/1410)) ([79992f1](https://github.com/hamlet-io/engine-plugin-aws/commit/79992f1f131e532df143116ab3cd334dcfd47e44))
* typos in entrances ([2a1ecf7](https://github.com/hamlet-io/engine-plugin-aws/commit/2a1ecf70c7d8cde8ec94b5b7875ca4f8b8f46fa8))
* **masterdata:** add global outbound rule description ([8c8af27](https://github.com/hamlet-io/engine-plugin-aws/commit/8c8af27dd2160b3922022cf0fcfa414aa1f2d4ba))
* typos in fragments ([0731cdc](https://github.com/hamlet-io/engine-plugin-aws/commit/0731cdcc1cc51db567dac88d2d00a8d396f80dc1))
* **account:** only run cmk checks in specific units ([d86584a](https://github.com/hamlet-io/engine-plugin-aws/commit/d86584a7c843dce99c793a96f22f2d1ce665c630))
* **accountlayer:** fix console logging ([5672925](https://github.com/hamlet-io/engine-plugin-aws/commit/567292520134cb4ea191bcc15dfba8ba3cbb28b8))
* **apigateway:** do not attempt eval if definitions full is null ([#1389](https://github.com/hamlet-io/engine-plugin-aws/issues/1389)) ([c26e9d6](https://github.com/hamlet-io/engine-plugin-aws/commit/c26e9d6ef970785b2586dda785b29281ce712ee1))
* **aws-iam:** add descriptions for service roles ([757c322](https://github.com/hamlet-io/engine-plugin-aws/commit/757c3227056ac5f6faa244f263ed7f917c5d919d))
* **bastion:** allow ssh when internet access disabled ([84c5115](https://github.com/hamlet-io/engine-plugin-aws/commit/84c5115bf064eab3aa60e55a676440e1ad0f2f52))
* **console:** allow for psuedo s3 buckets ([646d07d](https://github.com/hamlet-io/engine-plugin-aws/commit/646d07dea0a8401c28208b694aa6ce8e47074562))
* **datafeed:** update description ([2f6a6d1](https://github.com/hamlet-io/engine-plugin-aws/commit/2f6a6d1fc64ffd5ddb4a93de857325468a8e4504))
* **ecs:** add fragment and instance back to container props ([#1399](https://github.com/hamlet-io/engine-plugin-aws/issues/1399)) ([c146906](https://github.com/hamlet-io/engine-plugin-aws/commit/c1469068b5ab8bfdf4ebb666175f5003a701bb74))
* **ecs:** reinstate deployment details ([#1400](https://github.com/hamlet-io/engine-plugin-aws/issues/1400)) ([b5bde76](https://github.com/hamlet-io/engine-plugin-aws/commit/b5bde76ac945348c36647751e382c93c46b84f97))
* **ecs:** Volume drivers and support for control over volume engine ([92d70c6](https://github.com/hamlet-io/engine-plugin-aws/commit/92d70c67725731dcaa1b95d0162ce3f71265af55))
* **efs:** use children for ownership ([34bffd1](https://github.com/hamlet-io/engine-plugin-aws/commit/34bffd12ab272e683f92b060b2301d15b8927c18))
* **extensions:** use resolved alias id for lookups ([8f93b35](https://github.com/hamlet-io/engine-plugin-aws/commit/8f93b35ae55624dab896577e1a853eece6c54f5a))
* **externalservice:** Apply solution config on the resource group ([c2fd3e1](https://github.com/hamlet-io/engine-plugin-aws/commit/c2fd3e1e2acf22126662cbdb00939257ddaf72cf))
* **externalservice:** attribute name ([6a9fd5d](https://github.com/hamlet-io/engine-plugin-aws/commit/6a9fd5d8438d6b4dd9e80958ab96458066f71099))
* **externalservice:** fix var name for ip listing ([b2e115e](https://github.com/hamlet-io/engine-plugin-aws/commit/b2e115eb8895f7121c64d31a54ba48874c2ff8f1))
* **externalservice:** var name ([4f2ff77](https://github.com/hamlet-io/engine-plugin-aws/commit/4f2ff770345b40d200145b73d6bb03fd93ddc540))
* **fragment:** agent override for aws user ([2a196fd](https://github.com/hamlet-io/engine-plugin-aws/commit/2a196fd4368d0fe5d937a7e3d2580fcd7d4311a0))
* **fragment:** hamlet agent properties mounts ([#1397](https://github.com/hamlet-io/engine-plugin-aws/issues/1397)) ([a77e1bc](https://github.com/hamlet-io/engine-plugin-aws/commit/a77e1bc97cf519791b1d6a3b8d6f82fd57ccf68b))
* **gateway:** remove mandatory requirement on Endpoint details ([2281b89](https://github.com/hamlet-io/engine-plugin-aws/commit/2281b89e39833b00077125d4c7c8c0b64a286a60))
* **mock:** set a fixed runId for mock ([53f6654](https://github.com/hamlet-io/engine-plugin-aws/commit/53f665435653af1363e2a2e5eb84046f8b5e910a))
* **networkProfile:** enable or disable egress rules ([#1351](https://github.com/hamlet-io/engine-plugin-aws/issues/1351)) ([29d60f0](https://github.com/hamlet-io/engine-plugin-aws/commit/29d60f09bb7a82d5c8c27b552d68f8cfef6f3268))
* **openapi:** quota throttling only exists on a usage plan ([5e1b08e](https://github.com/hamlet-io/engine-plugin-aws/commit/5e1b08e5d3f19690d1b434528d3a0b4f39238283))
* **reference:** deployment mode default hanlding ([e350f4f](https://github.com/hamlet-io/engine-plugin-aws/commit/e350f4ff01f9476c34ae361fed9f927e81cba40f))
* update for ProviderId migration ([aef34d0](https://github.com/hamlet-io/engine-plugin-aws/commit/aef34d09e8e0696fbb026a7222483411115f13d2))
* use all units by default on resource lables ([c719705](https://github.com/hamlet-io/engine-plugin-aws/commit/c719705c99fa4f67d80b6525f04b5f741b6f8ba6))
* use perfect squares for subnet calculations ([1e56f9b](https://github.com/hamlet-io/engine-plugin-aws/commit/1e56f9b5d65278de1cf94dc21f501824254ea110))
* Wrapper fix for CMDB file system ([4271805](https://github.com/hamlet-io/engine-plugin-aws/commit/427180552e70105d5f6c5cb57e37709b60995759))
* **router:** bgp asn description ([9ddc783](https://github.com/hamlet-io/engine-plugin-aws/commit/9ddc783c0ddb95aa98970ec8fd4d489326737f71))
* **s3:** adds migration for queue permissions config ([28625b5](https://github.com/hamlet-io/engine-plugin-aws/commit/28625b5b43bb75baef7c5b81d4a4156ddabddbd4))
* **s3:** renamed global var back to dataOffline ([#1452](https://github.com/hamlet-io/engine-plugin-aws/issues/1452)) ([a3e3f1d](https://github.com/hamlet-io/engine-plugin-aws/commit/a3e3f1df8e64a2696ab93577809aabddaaee1eab))
* **schema:** metaparameters should not ref links ([15fa993](https://github.com/hamlet-io/engine-plugin-aws/commit/15fa993c4314c38b8085f889402a621c45bc1546))
* **settings:** evaluation preferences for setting namespaces ([3c9be44](https://github.com/hamlet-io/engine-plugin-aws/commit/3c9be44aa09a5c2d2d83dd3c08208926aa4bdd97))


### Code Refactoring

* dynamic loading of subset marcos ([27340a0](https://github.com/hamlet-io/engine-plugin-aws/commit/27340a0ea5b28cc95fdf247a564ca514db8daf0f))
* rename scenarios to modules ([4fdde3a](https://github.com/hamlet-io/engine-plugin-aws/commit/4fdde3a08083a8ba12daca075df52e1d65207180))


### Features

* **account:** allow unique cmk aliases ([1cb5822](https://github.com/hamlet-io/engine-plugin-aws/commit/1cb5822caf24a7bde5c5b3da4ba8faf5eda4c22e))
* **alerts:** get metric dimensions from blueprint ([#1490](https://github.com/hamlet-io/engine-plugin-aws/issues/1490)) ([a58bd30](https://github.com/hamlet-io/engine-plugin-aws/commit/a58bd304ac7a53748add577b8430d3aa878ed62d))
* **apigateway:** add quota throttling ([8700f16](https://github.com/hamlet-io/engine-plugin-aws/commit/8700f16807e5b726b29f000666c3cbc0502a8818))
* **apigateway:** added logstore attribute ([7937015](https://github.com/hamlet-io/engine-plugin-aws/commit/79370156f66bc37bccd9c9120ab59182784cf513))
* **apigateway:** support gateway and cdn https profiles ([33f3e17](https://github.com/hamlet-io/engine-plugin-aws/commit/33f3e17a523e05c295fada2a89bb27b1ff3baa24))
* **apigw + waf:** separate logging enabled from logging profiles ([#1435](https://github.com/hamlet-io/engine-plugin-aws/issues/1435)) ([c28ddd0](https://github.com/hamlet-io/engine-plugin-aws/commit/c28ddd0f5328641241ee22794789b1d3bc97efd4))
* **base:** add object searching using a keys ([689cc34](https://github.com/hamlet-io/engine-plugin-aws/commit/689cc348b6062eae3240daa1a9e5db4cd77c24ec))
* **console:** add dedicated cmk option for console sessions ([7f85bdc](https://github.com/hamlet-io/engine-plugin-aws/commit/7f85bdccaa5c6451aab51a4e4fca086e11a9d57f))
* **console:** Update console support for encryption ([9e1610d](https://github.com/hamlet-io/engine-plugin-aws/commit/9e1610d727e91b67199faa02a177b677b8ffb1b8))
* **containers:** ulimit configuration ([44392d9](https://github.com/hamlet-io/engine-plugin-aws/commit/44392d91c390018ad2a4d3d835ad9b778723c6a0))
* **core:** extend policy profiles to occurence level control ([2b4ef77](https://github.com/hamlet-io/engine-plugin-aws/commit/2b4ef77ffbb04dfa2ce9c0502ee01742923e0e19))
* **datafeed:** add deployment specifc indludes to prefix ([5a72166](https://github.com/hamlet-io/engine-plugin-aws/commit/5a72166b5803583dcdb7b07b24e23953aa6853e4))
* **datafeed:** deploy specifc prefixes ([9fb8f9e](https://github.com/hamlet-io/engine-plugin-aws/commit/9fb8f9ecfaa87ff1ceabe34641b80948c9fa0d97))
* **ec2:** volume encryption ([4cd1dfa](https://github.com/hamlet-io/engine-plugin-aws/commit/4cd1dfa91144bd07a86afc1c2c3ccfea187ec0ac))
* **ecs:** add healthcheck support ([5c9cbc5](https://github.com/hamlet-io/engine-plugin-aws/commit/5c9cbc52b0130b3f2cd38d978f264fc5b9c3f0f5))
* **ecs:** add hostname macro for containers ([a52f4cf](https://github.com/hamlet-io/engine-plugin-aws/commit/a52f4cff3edbfe043ff38067268332e7393c6bb2))
* **ecs:** add lookup for ingress rules based on links for containers ([0d6c802](https://github.com/hamlet-io/engine-plugin-aws/commit/0d6c8021065b725307fa38c70668009a988e34a0))
* **ecs:** add support for compute providers ([0ce39a7](https://github.com/hamlet-io/engine-plugin-aws/commit/0ce39a77be39300cd181e11118ee3a312b8f2306))
* **ecs:** allow for fragment and image override in solution ([2ac4ad4](https://github.com/hamlet-io/engine-plugin-aws/commit/2ac4ad4ae30f73e28fe5b6f4efd85f27738ffef4))
* **ecs:** fragment override and image override in solution ([f58b742](https://github.com/hamlet-io/engine-plugin-aws/commit/f58b74291d401213423cbbc80461d4ab61a3aa24))
* **ecs:** placement constraint support ([31c8206](https://github.com/hamlet-io/engine-plugin-aws/commit/31c82067e437576fb4c9d48c012206cbb89fd43e))
* **ecs:** support container image sourcing ([#1495](https://github.com/hamlet-io/engine-plugin-aws/issues/1495)) ([06f4a00](https://github.com/hamlet-io/engine-plugin-aws/commit/06f4a00cd4ea6d0eeec8f69feede60911ad9b3b5))
* **ecs:** support for efs volume mounts on ecs tasks ([3d2db45](https://github.com/hamlet-io/engine-plugin-aws/commit/3d2db45af5ada53d2556f58bd4de090c5c7b973b))
* **efs:** support chroot based on mount points ([d6e1605](https://github.com/hamlet-io/engine-plugin-aws/commit/d6e1605b301061318eebc819b37a6ddaa157c26c))
* **extensions:** Allow mutliple extensions ([0fd3c39](https://github.com/hamlet-io/engine-plugin-aws/commit/0fd3c399f588fcf326a7fb4b42656565bc8592c8))
* **extensions:** convert existing fragments ([9531f69](https://github.com/hamlet-io/engine-plugin-aws/commit/9531f6937b451f6a8cb1b5bf08cb11d3a3665453))
* **extensions:** support entrance extensions ([2122c8b](https://github.com/hamlet-io/engine-plugin-aws/commit/2122c8b49537ac7244bc3d773a0efbec50e406b9))
* **externalnetwork:** intial external network support ([2a52bc3](https://github.com/hamlet-io/engine-plugin-aws/commit/2a52bc3701fcf49b9588370b3ccc5c432d22397b))
* **externalnetwork+gateway:** vpn security profile ([2cc3441](https://github.com/hamlet-io/engine-plugin-aws/commit/2cc34416ad247aa887d87a561726948d703096d3))
* **externalservice:** add support for endpoints on an external service ([0148788](https://github.com/hamlet-io/engine-plugin-aws/commit/0148788cc8e4f32e7d8007708fd5b50eb592a546))
* **externalservice:** Attributes for external service endpoint ([464aa1e](https://github.com/hamlet-io/engine-plugin-aws/commit/464aa1e4e9c6fc5cb4f53761f951c4f589228adb))
* **externalservice:** Networkacl support ([a93db78](https://github.com/hamlet-io/engine-plugin-aws/commit/a93db78171180ef5c81234b489b675a99e2ecad5))
* **filetransfer:** security policy control ([275c738](https://github.com/hamlet-io/engine-plugin-aws/commit/275c73826a1ad644a0604ff47fe5912caba076fe))
* **filetransfer:** support for a file transfer component with user integration ([67d40dc](https://github.com/hamlet-io/engine-plugin-aws/commit/67d40dc50a849219c2c6f164d2cc36580c6c52b2))
* **fragment:** startup command setting for agent ([1709cca](https://github.com/hamlet-io/engine-plugin-aws/commit/1709ccab910b0f0620f351803bc8dca1cb948ad4))
* **gateway:** destination port control ([8b7741e](https://github.com/hamlet-io/engine-plugin-aws/commit/8b7741e0ba057b4e54484ba4b9868d286a20c464))
* **gateway:** destination port control for private services ([7c18532](https://github.com/hamlet-io/engine-plugin-aws/commit/7c18532d0c010f6cf14ad369f178cf31672ddf9b))
* **gateway:** dns configuration support ([8099e9d](https://github.com/hamlet-io/engine-plugin-aws/commit/8099e9d4b11927b1306dc1db3e34ff23bdb3a840))
* **gateway:** dynamic routing for private gw ([0e546fd](https://github.com/hamlet-io/engine-plugin-aws/commit/0e546fd21341de0a9fdfb4978b5b5078b811f56f))
* **gateway:** private gateway ([5c9d0dd](https://github.com/hamlet-io/engine-plugin-aws/commit/5c9d0ddb2a2c92a5144e6dfa36c277520f41962c))
* **gateway:** support for the router component as an engine ([5c3b73a](https://github.com/hamlet-io/engine-plugin-aws/commit/5c3b73ae9020f6112af3b2e446ece80ed3603067))
* **globaldb:** intial support for global dbs ([#1325](https://github.com/hamlet-io/engine-plugin-aws/issues/1325)) ([4cab2ad](https://github.com/hamlet-io/engine-plugin-aws/commit/4cab2ada2d356c6a8a7e750e16de65e604053143))
* **hamlet-agent:** allow for agent level az tenant id ([32837eb](https://github.com/hamlet-io/engine-plugin-aws/commit/32837eb6f691f651fa98593279034a09a309df7b))
* **jenkins:** add support for dind in hamlet agents ([e526e7e](https://github.com/hamlet-io/engine-plugin-aws/commit/e526e7e0d9b2c2b55057593780eee9a6d551b63b))
* **jenkins:** add support for permanent ecs agents ([#1321](https://github.com/hamlet-io/engine-plugin-aws/issues/1321)) ([05b8290](https://github.com/hamlet-io/engine-plugin-aws/commit/05b8290f68ed8ed204b979da7d6c4f2c3733c31a))
* **lambda:** pull images from external source ([#1456](https://github.com/hamlet-io/engine-plugin-aws/issues/1456)) ([dbc5a77](https://github.com/hamlet-io/engine-plugin-aws/commit/dbc5a773c90a009a57ca3d1a9f1b7b32c8dbd786))
* **lb:** add static endpoint forwarding ([c72a615](https://github.com/hamlet-io/engine-plugin-aws/commit/c72a6154f5137b5a33e4c8d0e1e258adc134955b))
* **lb:** Network load balancer TLS offload ([76f8a94](https://github.com/hamlet-io/engine-plugin-aws/commit/76f8a94fb4919d35f65d55adacdb22195cb34e52))
* **lb:** WAF integration ([63d139b](https://github.com/hamlet-io/engine-plugin-aws/commit/63d139b3d669796ba67c14e54014695afa59e688))
* **links:** incl. support for case-insensitive link direction ([95b62aa](https://github.com/hamlet-io/engine-plugin-aws/commit/95b62aac0bf26006350aa8703973770b912b0903))
* **masterdata:** add additional rabbitmq port definitions for queuehost ([ae01e9b](https://github.com/hamlet-io/engine-plugin-aws/commit/ae01e9beda66804363d84992dacd30deae2c6c04))
* **mobileapp:** OTA Support on CDN routes ([#1319](https://github.com/hamlet-io/engine-plugin-aws/issues/1319)) ([4e85e17](https://github.com/hamlet-io/engine-plugin-aws/commit/4e85e17c2edac7993ea7a0273699581dcb0e8f4f))
* **network:** flow log control ([69e3731](https://github.com/hamlet-io/engine-plugin-aws/commit/69e373174053417a6b8b649fcc0089e3280ab055))
* **occurrence:** Setting namespaces for occurrence ([56345fe](https://github.com/hamlet-io/engine-plugin-aws/commit/56345fec897e6949ef1c2365d1027c1fb74c6b37))
* **occurrence:** support caching of occurrences ([41d1183](https://github.com/hamlet-io/engine-plugin-aws/commit/41d1183bcfb65dacf7fbd069e7081ebdd5c6a41b))
* support deployment document generation using group filters ([b905071](https://github.com/hamlet-io/engine-plugin-aws/commit/b905071492ee72dd17bd00a978bf806cb25685ae))
* **openapi:** enable throttling settings on apigw ([f4cf8f0](https://github.com/hamlet-io/engine-plugin-aws/commit/f4cf8f00ff0cba3fc767d01d232c2cfe3601e6ee))
* **privateservice:** intial support for private services ([#1330](https://github.com/hamlet-io/engine-plugin-aws/issues/1330)) ([1f2169b](https://github.com/hamlet-io/engine-plugin-aws/commit/1f2169baaec821e3ffe3894477eace3f689adbc4))
* **queuehost:** initial definition ([a884bb2](https://github.com/hamlet-io/engine-plugin-aws/commit/a884bb26300e4796e64e807483ad39097f097134))
* **registry:** support for mutli region registry ([6df845e](https://github.com/hamlet-io/engine-plugin-aws/commit/6df845e5afeaacbcde9573decd75f2d0c6837275))
* **router:** adds initial support for the router component ([9ecc76e](https://github.com/hamlet-io/engine-plugin-aws/commit/9ecc76e189f809036649c398dd5d24f22e7a7733))
* **router:** make BGP ASN mandatory ([b757303](https://github.com/hamlet-io/engine-plugin-aws/commit/b757303eee35369e5518f791980f2499334122fe))
* **router:** static route support ([574a030](https://github.com/hamlet-io/engine-plugin-aws/commit/574a030d2d7a5b7be7ce35b501b0d9d321b833ac))
* **s3:** account level S3 Encryption ([1264ff9](https://github.com/hamlet-io/engine-plugin-aws/commit/1264ff904fef4c882548291ff728aa9ad4e97778))
* **s3:** add configuration support s3 Encryption ([282aa2f](https://github.com/hamlet-io/engine-plugin-aws/commit/282aa2f94dbeda66a34aec4e08a51eb96689847a))
* **s3:** baseline s3 encryption permissions ([214c030](https://github.com/hamlet-io/engine-plugin-aws/commit/214c030cedf355ca044f3fec52e2ca2a645df9cb))
* **schema:** add required property to jsonschemas ([#1367](https://github.com/hamlet-io/engine-plugin-aws/issues/1367)) ([f5f98fb](https://github.com/hamlet-io/engine-plugin-aws/commit/f5f98fb9c1a9cfc8aff195017a1c36a90aa1d6d4))
* Network rule component configuration ([fda7396](https://github.com/hamlet-io/engine-plugin-aws/commit/fda7396730e87e1f404d08c77c336fea83f3eab8))
* **schema:** added subsets for reference data and component schema ([b3db31d](https://github.com/hamlet-io/engine-plugin-aws/commit/b3db31d0a1bb64aa08caea12c0013ffa4488e22c))
* **schema:** default output - schema ([d384f90](https://github.com/hamlet-io/engine-plugin-aws/commit/d384f905e2ea6596810168fc1ff3305c809d0c2b))
* **secretstore:** new component type - secretstore ([7b93c76](https://github.com/hamlet-io/engine-plugin-aws/commit/7b93c76a152ed734068cc2f60767130ae55fc00c))
* **secretstore:** update configuration and make it shareable ([#1484](https://github.com/hamlet-io/engine-plugin-aws/issues/1484)) ([d1f977a](https://github.com/hamlet-io/engine-plugin-aws/commit/d1f977ae599f661e39968331d56c5052a01a3c11))
* **testcases:** add additional output suffix types. ([e79b0f2](https://github.com/hamlet-io/engine-plugin-aws/commit/e79b0f202dee1a7793633238d96e451640318017))
* **userpool:** Add Encryption schema to client secrets ([dcc0571](https://github.com/hamlet-io/engine-plugin-aws/commit/dcc0571ece75b92d8ee6c5a83bb1f90aae1c6c6e))
* "Account" and fixed build scope ([#1402](https://github.com/hamlet-io/engine-plugin-aws/issues/1402)) ([258e32b](https://github.com/hamlet-io/engine-plugin-aws/commit/258e32b8ac857806997f1b12250461605d66602c))
* account inbound ses configuration ([ad8e377](https://github.com/hamlet-io/engine-plugin-aws/commit/ad8e3775caa3f641e5ab5dc966334ad52e7941ae))
* add databucket replication attributes ([#1411](https://github.com/hamlet-io/engine-plugin-aws/issues/1411)) ([2eaf5d5](https://github.com/hamlet-io/engine-plugin-aws/commit/2eaf5d5a94f46dbf3ecdd8fad36bc2476243f7e0))
* add deployment component attributes ([d88431c](https://github.com/hamlet-io/engine-plugin-aws/commit/d88431c19daf808f576df59097955d4d78824810))
* add deployment groups for unit and level control ([23a89b0](https://github.com/hamlet-io/engine-plugin-aws/commit/23a89b05fd885e56031e53bca37ca987c14b93a4))
* add engine attr to containerhost ([aff09a5](https://github.com/hamlet-io/engine-plugin-aws/commit/aff09a51744ccf487f897d0bca07aac135968e1b))
* Add engine support for layers ([126fbd3](https://github.com/hamlet-io/engine-plugin-aws/commit/126fbd3a361b4740cf4c54f029cfc1f0a5ae9700))
* add host from network util ([cab414c](https://github.com/hamlet-io/engine-plugin-aws/commit/cab414c8348f49077796080c275e918dc167aecc))
* add operations and provider to mgmt ([72703d9](https://github.com/hamlet-io/engine-plugin-aws/commit/72703d95848b9a41f4c73de676f77d76298b30fb))
* add policy to core component config ([ce15bb5](https://github.com/hamlet-io/engine-plugin-aws/commit/ce15bb547e44f2d48d9c8d95cce36cd42e3fc8f1))
* add processor profiles ([05da8ee](https://github.com/hamlet-io/engine-plugin-aws/commit/05da8eedaa0bf903a74530f9c0d49ab6100868c2))
* add reference definitions for profiles ([9d62654](https://github.com/hamlet-io/engine-plugin-aws/commit/9d62654f1b5d8a4653ebd2d8b6cb28bf1aa5f40c))
* add resource labels to support resourceSets in deployment groups ([23e2c32](https://github.com/hamlet-io/engine-plugin-aws/commit/23e2c32b93c9dd21f68bc92846bb38b7d4c747c1))
* add scenario loading through blueprint ([422bd43](https://github.com/hamlet-io/engine-plugin-aws/commit/422bd4309c68df785063a83312156e2e0a737b2d))
* add scenario profile reference type ([45af67e](https://github.com/hamlet-io/engine-plugin-aws/commit/45af67e241d69eb6cf7f3e81a8e5c410c6e7cc9e))
* add service role provisioing to account level ([ecfbcb4](https://github.com/hamlet-io/engine-plugin-aws/commit/ecfbcb4797275461dc969ae79352b0883965906d))
* add service role reference ([41dba2a](https://github.com/hamlet-io/engine-plugin-aws/commit/41dba2a1c3dac83732a8e0c2ed3065422440ff6a))
* add support for token validity expressions ([#1409](https://github.com/hamlet-io/engine-plugin-aws/issues/1409)) ([0e128a7](https://github.com/hamlet-io/engine-plugin-aws/commit/0e128a7be5015c3d687f39f9419fc30445bb0891))
* allow setting encryption scheme for attributes ([6507868](https://github.com/hamlet-io/engine-plugin-aws/commit/6507868af2608f09f31b3f7b53272a8a3fed6cf9))
* API gateway error format control ([8f9eb3a](https://github.com/hamlet-io/engine-plugin-aws/commit/8f9eb3a3c10149174dc512f997b65c087775c824))
* aws ecs account settings ([44f8f3e](https://github.com/hamlet-io/engine-plugin-aws/commit/44f8f3e62ef1d035288b33266d8ee64051ba2420))
* Bucket cleanup optional when copying files ([07cccf0](https://github.com/hamlet-io/engine-plugin-aws/commit/07cccf0c6ad50ba1dc080d32644cdc2a6bfdb2d7))
* bug-feature templates for issues ([d86b8ab](https://github.com/hamlet-io/engine-plugin-aws/commit/d86b8abfe8ca94071dbe8160bf505303ea6cfa69))
* component deployment attributes ([be4865f](https://github.com/hamlet-io/engine-plugin-aws/commit/be4865fa2602173bddbab72ee9c01df8505225d9))
* consolidate level clients in line with deployment groups ([f0e3dd5](https://github.com/hamlet-io/engine-plugin-aws/commit/f0e3dd56b0b522c275063a7ad04f830c9dbf9bf7))
* Container support for network profiles ([90dc7b6](https://github.com/hamlet-io/engine-plugin-aws/commit/90dc7b6a8d0c7fe04f930a6803486ebd5ce4f041))
* define layers in shared provider ([358a034](https://github.com/hamlet-io/engine-plugin-aws/commit/358a034f5afd917fcadcc66928e7dc22413f398a))
* deployment mode and group refernce ([8f1c8c3](https://github.com/hamlet-io/engine-plugin-aws/commit/8f1c8c3a258d3f81a0649079ba6a8ec20497f8b8))
* document set support ([ab6dda4](https://github.com/hamlet-io/engine-plugin-aws/commit/ab6dda4b9047ea5cde71177f0e63a0100f69d343))
* dynamic model loading and scopes ([d5062b7](https://github.com/hamlet-io/engine-plugin-aws/commit/d5062b75203ecaa2c99d593935ddbea0d0e6656c))
* fragment migration to extensions ([6fef804](https://github.com/hamlet-io/engine-plugin-aws/commit/6fef804b3a8407ebb479e318d13596aeb7f31618))
* Generic check for type in authentication header ([137fc60](https://github.com/hamlet-io/engine-plugin-aws/commit/137fc60b56fb53e6fa91055d435c53475327265d))
* globaldb secondary indexes ([#1507](https://github.com/hamlet-io/engine-plugin-aws/issues/1507)) ([86ac1c0](https://github.com/hamlet-io/engine-plugin-aws/commit/86ac1c0c108d87399a8c69ecb90c7a5a8c0ece84))
* hamlet info view ([913d021](https://github.com/hamlet-io/engine-plugin-aws/commit/913d021ad82b5ae2079b15733d76b9805405a706))
* manage one off instance failures ([aed0a8d](https://github.com/hamlet-io/engine-plugin-aws/commit/aed0a8d2e45cfdd3f0491a466edbe1c09d789575))
* management contract generation ([5327a02](https://github.com/hamlet-io/engine-plugin-aws/commit/5327a027bbe1f0519582ecaa603e6902423d7ce0))
* MTA component ([493cd3b](https://github.com/hamlet-io/engine-plugin-aws/commit/493cd3b2426f7845cf285a53d86b283ff3e5786c))
* network profiles ([2ce49fe](https://github.com/hamlet-io/engine-plugin-aws/commit/2ce49fe403ee954912a735295df612d2c166f627))
* os patching in solution config ([cd698d5](https://github.com/hamlet-io/engine-plugin-aws/commit/cd698d5b4f485ce73fc53c45b582b6ba8806472c))
* s3 sync exclude support ([9120899](https://github.com/hamlet-io/engine-plugin-aws/commit/9120899186efc06c0dd53e50b5244f646376bfad))
* semver support ([#1434](https://github.com/hamlet-io/engine-plugin-aws/issues/1434)) ([016cd80](https://github.com/hamlet-io/engine-plugin-aws/commit/016cd80a1998e70cad1391c55a7691fedaca018e))
* set container level auth method for hamlet agent ([24489a0](https://github.com/hamlet-io/engine-plugin-aws/commit/24489a07b8673321a22bcfd2988e21a89369b544))
* set default deployment group for all components ([d4301e1](https://github.com/hamlet-io/engine-plugin-aws/commit/d4301e1e7291e44b709643004020cafecbabf4e5))
* splitting out container components ([49a7ab1](https://github.com/hamlet-io/engine-plugin-aws/commit/49a7ab10ee40580a0e1a99bbefb35a2f9b47df64))
* **userpool:** control oauth on clients ([c550e50](https://github.com/hamlet-io/engine-plugin-aws/commit/c550e50ae4f4c8a03db65417e36aba884f9d6e7d))
* **waf:** add waf logging profiles ([d431a8a](https://github.com/hamlet-io/engine-plugin-aws/commit/d431a8aa29cdb88abc2a5d40f0b0c7ece2f1e108))
* support deployment group filtering on occurrences ([ed397e4](https://github.com/hamlet-io/engine-plugin-aws/commit/ed397e4b8cbac5f30c52a81a123fb852b2c96d78))
* support for centralised service resources ([cd762b8](https://github.com/hamlet-io/engine-plugin-aws/commit/cd762b8fc68687b4ceeee529f9f838d171d09911))
* template control per api gateway status ([771a37d](https://github.com/hamlet-io/engine-plugin-aws/commit/771a37d22c1dfd94d84af755947a246fa0969eaa))
* tier based network lookup ([#1359](https://github.com/hamlet-io/engine-plugin-aws/issues/1359)) ([6e9f710](https://github.com/hamlet-io/engine-plugin-aws/commit/6e9f7107b0cdbf3454b8a05c11a908a1e1ccdfd9))
* update format for deployment groups to incldue name/id ([66faa02](https://github.com/hamlet-io/engine-plugin-aws/commit/66faa02f165f13e44bb414c82566a7c2a8267843))
* views for blueprint and schema ([7ae367e](https://github.com/hamlet-io/engine-plugin-aws/commit/7ae367ecd57b8e52f53fbe626d7e8f0b5caa81c0))


### BREAKING CHANGES

* any calls to macro invocations for scenarios will now
be to modules, the scenarioProfile has also been removed, instead the
scenario configuration is provided directly to a layer
* **ecs:** this also removes the existing ComputeProvider option
on the ECS component in favour of a more configurable approach
* The scenario format and loading process has now changed
to support this
* All Component macros now need to include an entrance as
part of their name to allow for different macros based on entrance



# [](https://github.com/roleyfoley/engine/compare/v7.0.0...v) (2021-01-11)


### Bug Fixes

* 403 status on authorizer failure ([9a25bd0](https://github.com/roleyfoley/engine/commit/9a25bd0d41c9f0091c5accc9ba23f8f7b33f6634))
* Add dummy end.ftl for accounts composite ([51198a8](https://github.com/roleyfoley/engine/commit/51198a8b4f638443e42521517d77bbda54a8038a))
* add settings back in to bootstraps ([2d29252](https://github.com/roleyfoley/engine/commit/2d29252888df54db5259852fa3e1cd73c2be51ab))
* align resource sets with latest deployment groups ([24785c3](https://github.com/roleyfoley/engine/commit/24785c368c3d3ef38427a6ec59a6003004be79df))
* allow for undefined networkendpoints on a region ([#1427](https://github.com/roleyfoley/engine/issues/1427)) ([58a0342](https://github.com/roleyfoley/engine/commit/58a0342aab86eb6d512df98490e9f10ed5b1f764))
* authorizer failure messages ([9e8a785](https://github.com/roleyfoley/engine/commit/9e8a7856e2b027f67483917eb4ffdcfa8397bb0b))
* better control over scope combination ([34a8894](https://github.com/roleyfoley/engine/commit/34a8894b4e3e01a5c91ef58df14748d04a84c4dd))
* case insensitive token validity expression ([58ace15](https://github.com/roleyfoley/engine/commit/58ace154c7197b399d66ecb641a7317008595a1a))
* comments on resource label definition ([de2321f](https://github.com/roleyfoley/engine/commit/de2321fd840eb0681c277709d373dd1017551560))
* corrected call to child component macro ([0bed2b0](https://github.com/roleyfoley/engine/commit/0bed2b0d8b3e04a0ff48f9c39afaa27a930837e9))
* detect missing data volumes ([2b9177d](https://github.com/roleyfoley/engine/commit/2b9177d1e43faeef1953c973c2bd5c975e2563c2))
* determine a primary provider to use for views ([#1422](https://github.com/roleyfoley/engine/issues/1422)) ([6688a73](https://github.com/roleyfoley/engine/commit/6688a73739a30b4d79ca9b7d9dc9b042c73862f4))
* dind hostname and image details ([#1503](https://github.com/roleyfoley/engine/issues/1503)) ([d36e8ca](https://github.com/roleyfoley/engine/commit/d36e8ca03968db4f9d936e727f0e5099a7b415f4))
* engine updates from testing ([69e5cc8](https://github.com/roleyfoley/engine/commit/69e5cc8212dc7f7b44d6bdb7e3c9821ad3131cd8))
* ensure service linked roles exist for volume encryption ([d62765c](https://github.com/roleyfoley/engine/commit/d62765c03cbd11877c13431b8c200467a6a26aee))
* entrance params and log messages ([bf1ac49](https://github.com/roleyfoley/engine/commit/bf1ac49b5c354aa82e90b9ff044296b3fcd87a26))
* erroneous bracket ([#1501](https://github.com/roleyfoley/engine/issues/1501)) ([8d0230f](https://github.com/roleyfoley/engine/commit/8d0230f0c3f3fa317154682312945966e50c6f7c))
* expand range of certificate behaviours ([e4b4499](https://github.com/roleyfoley/engine/commit/e4b4499f0241213031f983d59eb61adcd854a6d5))
* explicit auth disable for options ([778fff8](https://github.com/roleyfoley/engine/commit/778fff8d5703cbd4588a38145cc7e167a933e175))
* Explicit mock API passthrough behaviour ([#1401](https://github.com/roleyfoley/engine/issues/1401)) ([bfed07c](https://github.com/roleyfoley/engine/commit/bfed07c398018f9d02563945ad93a964b18514cc))
* handle missing output mappings for resources ([2a70608](https://github.com/roleyfoley/engine/commit/2a70608a74d2cda0b95873f56050bef12e8ac8ce))
* handle no deploymentunit ([#1392](https://github.com/roleyfoley/engine/issues/1392)) ([6d0a51a](https://github.com/roleyfoley/engine/commit/6d0a51ae11e1cb948f1ac827900913576befc530))
* hanlde missing values for lambda ([d53ddf8](https://github.com/roleyfoley/engine/commit/d53ddf85f013342ba466685f0bf17104c54bf26e))
* host filtering for networks ([1a627a9](https://github.com/roleyfoley/engine/commit/1a627a9c9a20245db4cf64737de7f4fcd69376f7))
* If no CIDRs defined, getGroupCIDRs should return false ([0a7344c](https://github.com/roleyfoley/engine/commit/0a7344c581da0bdd89fdf050600e5c338c3ac75a))
* include int and version in occurrence caching ([#1451](https://github.com/roleyfoley/engine/issues/1451)) ([833acee](https://github.com/roleyfoley/engine/commit/833acee6b7af0af60ff1404a2971924cdfc5c413))
* layer attribute searching ([00bb41e](https://github.com/roleyfoley/engine/commit/00bb41e44637cdbb659767ab1416e46c3bc4469d))
* macro lookup processing array handling ([1c09893](https://github.com/roleyfoley/engine/commit/1c098937b63f538837392768d01fef57b5ad5fac))
* masterdata inclusion in blueprint ([f44df57](https://github.com/roleyfoley/engine/commit/f44df5782e04b3e1386eaf67a0bcf6a630e5a3eb))
* minor typos ([539552c](https://github.com/roleyfoley/engine/commit/539552c37dd07f41ec2d1a7103a89ade3d0dfa80))
* move link target to context support template ([f0ff218](https://github.com/roleyfoley/engine/commit/f0ff21891a424ec4e7b0702c6d6e3bb2be8effd4))
* moved engine type from containerServiceAtttributes to only exist on the ecs component ([b94d16f](https://github.com/roleyfoley/engine/commit/b94d16f587e4cdfd7a7d0bbacab963986d689b2c))
* only apply basic deployment groups for shared provider ([17a2df5](https://github.com/roleyfoley/engine/commit/17a2df5a98d40f35f0154bd1999fba9da9ccf282))
* output to use arrays ([c94a46a](https://github.com/roleyfoley/engine/commit/c94a46a5966ac84bfb20c602eef3321378200970))
* Output type for pregeneration scripts ([#1394](https://github.com/roleyfoley/engine/issues/1394)) ([17def79](https://github.com/roleyfoley/engine/commit/17def7993e34dd6bce9bfed75711335cbf1e5368))
* parameter ordering for invokeViewMacro ([#1428](https://github.com/roleyfoley/engine/issues/1428)) ([3286440](https://github.com/roleyfoley/engine/commit/32864408123f347f1853b3cdb4ba1ac162822ef8))
* perfect square calculation ([ae4b4d1](https://github.com/roleyfoley/engine/commit/ae4b4d1c9a29b562889fded105dd3f8a3a2f3653))
* possible certificate behaviour attributes ([4fbb44a](https://github.com/roleyfoley/engine/commit/4fbb44a4ce782a7490ba0aa6214df1b3ef4c0155))
* Pregeneration output format ([#1395](https://github.com/roleyfoley/engine/issues/1395)) ([1638ad3](https://github.com/roleyfoley/engine/commit/1638ad3f0e90394b1ed9d0998d98635d59c5984c))
* provide deployment unit to build settings ([d3215fe](https://github.com/roleyfoley/engine/commit/d3215fe641b9e50906a1e2e013743bc78b495936))
* provider updates from testing ([060fa19](https://github.com/roleyfoley/engine/commit/060fa190dc78df1c6545b2e6a41183e98edb5f99))
* reinstate link casing changes ([82f390e](https://github.com/roleyfoley/engine/commit/82f390ed59cb1d15be8e69d070d15693dd7a35ca))
* reinstate schema output type ([9220a45](https://github.com/roleyfoley/engine/commit/9220a452d18f9d1ab1b573ce52f48c26834a7d45))
* Remove auth provider defaults ([#1313](https://github.com/roleyfoley/engine/issues/1313)) ([1a726c1](https://github.com/roleyfoley/engine/commit/1a726c159cc63125f2c6a1c276bbcbff3fe83b7f))
* remove console only support in bastion ([55272ff](https://github.com/roleyfoley/engine/commit/55272ffbfc71067fb0d3f171042f24d2308b0ced))
* remove copy and paste error ([71998ed](https://github.com/roleyfoley/engine/commit/71998ed19db99c687a02a281d6f3af4369fd005d))
* remove legacy component properties ([a795555](https://github.com/roleyfoley/engine/commit/a79555509ac405f40b91a2d463dd11462dff13b1))
* remove legacy naming for fragment ([0d606ee](https://github.com/roleyfoley/engine/commit/0d606ee0d3676ea70f1059b2fbc12ab5579889ae))
* remove networkacl policies from iam links ([#1386](https://github.com/roleyfoley/engine/issues/1386)) ([9f38808](https://github.com/roleyfoley/engine/commit/9f388084b235b6d9d18a619c29e283bfd6d64987))
* remove service linked role check for cmk ([79ea4b8](https://github.com/roleyfoley/engine/commit/79ea4b8986ee43fd7da27ad620251d58336df69a))
* remove unused deployment group config ([d2338df](https://github.com/roleyfoley/engine/commit/d2338dfa6797eed906b6bfc627605a7703fa7905))
* semver supports asterisk in range indicator ([#1438](https://github.com/roleyfoley/engine/issues/1438)) ([8b11697](https://github.com/roleyfoley/engine/commit/8b1169739fedab02843cfdbb868071af64e8e3bc))
* setup contract outputs in resourceset ([#1419](https://github.com/roleyfoley/engine/issues/1419)) ([12eed31](https://github.com/roleyfoley/engine/commit/12eed31d1335f793463538c13f0ec1d466bd7522))
* Subcomponent config on instance/version ([2ea633e](https://github.com/roleyfoley/engine/commit/2ea633e89653e92c0e5cb504b19ae837942673cb))
* support buckets without at rest encryption ([534b56a](https://github.com/roleyfoley/engine/commit/534b56a1bf987dd64b90dfc4a375b5b6d3a8650a))
* support missing extension ([0c951a4](https://github.com/roleyfoley/engine/commit/0c951a4a6cc8882e157be8cf617f6bb8dc401038))
* syntax and variable name updates for build scopes ([#1403](https://github.com/roleyfoley/engine/issues/1403)) ([389630f](https://github.com/roleyfoley/engine/commit/389630fdb97e84e673e335b2962fea21d17204ce))
* typo in component ([d82c2fb](https://github.com/roleyfoley/engine/commit/d82c2fb6d1981a436cb82bf2fd2b6cfce1bbf4e5))
* typo in function name ([2d4d4d6](https://github.com/roleyfoley/engine/commit/2d4d4d61ddfcfb5d7e042c3806c46c020e2bbf09))
* typo in function names ([2513731](https://github.com/roleyfoley/engine/commit/2513731122d9e9dd3e10ad2976f798ece285eb03))
* typo in openapi syntax ([#1410](https://github.com/roleyfoley/engine/issues/1410)) ([79992f1](https://github.com/roleyfoley/engine/commit/79992f1f131e532df143116ab3cd334dcfd47e44))
* typos in entrances ([2a1ecf7](https://github.com/roleyfoley/engine/commit/2a1ecf70c7d8cde8ec94b5b7875ca4f8b8f46fa8))
* **masterdata:** add global outbound rule description ([8c8af27](https://github.com/roleyfoley/engine/commit/8c8af27dd2160b3922022cf0fcfa414aa1f2d4ba))
* typos in fragments ([0731cdc](https://github.com/roleyfoley/engine/commit/0731cdcc1cc51db567dac88d2d00a8d396f80dc1))
* **account:** only run cmk checks in specific units ([d86584a](https://github.com/roleyfoley/engine/commit/d86584a7c843dce99c793a96f22f2d1ce665c630))
* **accountlayer:** fix console logging ([5672925](https://github.com/roleyfoley/engine/commit/567292520134cb4ea191bcc15dfba8ba3cbb28b8))
* **apigateway:** do not attempt eval if definitions full is null ([#1389](https://github.com/roleyfoley/engine/issues/1389)) ([c26e9d6](https://github.com/roleyfoley/engine/commit/c26e9d6ef970785b2586dda785b29281ce712ee1))
* **aws-iam:** add descriptions for service roles ([757c322](https://github.com/roleyfoley/engine/commit/757c3227056ac5f6faa244f263ed7f917c5d919d))
* **bastion:** allow ssh when internet access disabled ([84c5115](https://github.com/roleyfoley/engine/commit/84c5115bf064eab3aa60e55a676440e1ad0f2f52))
* **console:** allow for psuedo s3 buckets ([646d07d](https://github.com/roleyfoley/engine/commit/646d07dea0a8401c28208b694aa6ce8e47074562))
* **datafeed:** update description ([2f6a6d1](https://github.com/roleyfoley/engine/commit/2f6a6d1fc64ffd5ddb4a93de857325468a8e4504))
* **ecs:** add fragment and instance back to container props ([#1399](https://github.com/roleyfoley/engine/issues/1399)) ([c146906](https://github.com/roleyfoley/engine/commit/c1469068b5ab8bfdf4ebb666175f5003a701bb74))
* **ecs:** reinstate deployment details ([#1400](https://github.com/roleyfoley/engine/issues/1400)) ([b5bde76](https://github.com/roleyfoley/engine/commit/b5bde76ac945348c36647751e382c93c46b84f97))
* **ecs:** Volume drivers and support for control over volume engine ([92d70c6](https://github.com/roleyfoley/engine/commit/92d70c67725731dcaa1b95d0162ce3f71265af55))
* **efs:** use children for ownership ([34bffd1](https://github.com/roleyfoley/engine/commit/34bffd12ab272e683f92b060b2301d15b8927c18))
* **extensions:** use resolved alias id for lookups ([8f93b35](https://github.com/roleyfoley/engine/commit/8f93b35ae55624dab896577e1a853eece6c54f5a))
* **externalservice:** Apply solution config on the resource group ([c2fd3e1](https://github.com/roleyfoley/engine/commit/c2fd3e1e2acf22126662cbdb00939257ddaf72cf))
* **externalservice:** attribute name ([6a9fd5d](https://github.com/roleyfoley/engine/commit/6a9fd5d8438d6b4dd9e80958ab96458066f71099))
* **externalservice:** fix var name for ip listing ([b2e115e](https://github.com/roleyfoley/engine/commit/b2e115eb8895f7121c64d31a54ba48874c2ff8f1))
* **externalservice:** var name ([4f2ff77](https://github.com/roleyfoley/engine/commit/4f2ff770345b40d200145b73d6bb03fd93ddc540))
* **fragment:** agent override for aws user ([2a196fd](https://github.com/roleyfoley/engine/commit/2a196fd4368d0fe5d937a7e3d2580fcd7d4311a0))
* **fragment:** hamlet agent properties mounts ([#1397](https://github.com/roleyfoley/engine/issues/1397)) ([a77e1bc](https://github.com/roleyfoley/engine/commit/a77e1bc97cf519791b1d6a3b8d6f82fd57ccf68b))
* **gateway:** remove mandatory requirement on Endpoint details ([2281b89](https://github.com/roleyfoley/engine/commit/2281b89e39833b00077125d4c7c8c0b64a286a60))
* **mock:** set a fixed runId for mock ([53f6654](https://github.com/roleyfoley/engine/commit/53f665435653af1363e2a2e5eb84046f8b5e910a))
* **networkProfile:** enable or disable egress rules ([#1351](https://github.com/roleyfoley/engine/issues/1351)) ([29d60f0](https://github.com/roleyfoley/engine/commit/29d60f09bb7a82d5c8c27b552d68f8cfef6f3268))
* **openapi:** quota throttling only exists on a usage plan ([5e1b08e](https://github.com/roleyfoley/engine/commit/5e1b08e5d3f19690d1b434528d3a0b4f39238283))
* **reference:** deployment mode default hanlding ([e350f4f](https://github.com/roleyfoley/engine/commit/e350f4ff01f9476c34ae361fed9f927e81cba40f))
* update for ProviderId migration ([aef34d0](https://github.com/roleyfoley/engine/commit/aef34d09e8e0696fbb026a7222483411115f13d2))
* use all units by default on resource lables ([c719705](https://github.com/roleyfoley/engine/commit/c719705c99fa4f67d80b6525f04b5f741b6f8ba6))
* use perfect squares for subnet calculations ([1e56f9b](https://github.com/roleyfoley/engine/commit/1e56f9b5d65278de1cf94dc21f501824254ea110))
* Wrapper fix for CMDB file system ([4271805](https://github.com/roleyfoley/engine/commit/427180552e70105d5f6c5cb57e37709b60995759))
* **router:** bgp asn description ([9ddc783](https://github.com/roleyfoley/engine/commit/9ddc783c0ddb95aa98970ec8fd4d489326737f71))
* **s3:** adds migration for queue permissions config ([28625b5](https://github.com/roleyfoley/engine/commit/28625b5b43bb75baef7c5b81d4a4156ddabddbd4))
* **s3:** renamed global var back to dataOffline ([#1452](https://github.com/roleyfoley/engine/issues/1452)) ([a3e3f1d](https://github.com/roleyfoley/engine/commit/a3e3f1df8e64a2696ab93577809aabddaaee1eab))
* **schema:** metaparameters should not ref links ([15fa993](https://github.com/roleyfoley/engine/commit/15fa993c4314c38b8085f889402a621c45bc1546))
* **settings:** evaluation preferences for setting namespaces ([3c9be44](https://github.com/roleyfoley/engine/commit/3c9be44aa09a5c2d2d83dd3c08208926aa4bdd97))


### Code Refactoring

* dynamic loading of subset marcos ([27340a0](https://github.com/roleyfoley/engine/commit/27340a0ea5b28cc95fdf247a564ca514db8daf0f))
* rename scenarios to modules ([4fdde3a](https://github.com/roleyfoley/engine/commit/4fdde3a08083a8ba12daca075df52e1d65207180))


### Features

* **account:** allow unique cmk aliases ([1cb5822](https://github.com/roleyfoley/engine/commit/1cb5822caf24a7bde5c5b3da4ba8faf5eda4c22e))
* **alerts:** get metric dimensions from blueprint ([#1490](https://github.com/roleyfoley/engine/issues/1490)) ([a58bd30](https://github.com/roleyfoley/engine/commit/a58bd304ac7a53748add577b8430d3aa878ed62d))
* **apigateway:** add quota throttling ([8700f16](https://github.com/roleyfoley/engine/commit/8700f16807e5b726b29f000666c3cbc0502a8818))
* **apigateway:** added logstore attribute ([7937015](https://github.com/roleyfoley/engine/commit/79370156f66bc37bccd9c9120ab59182784cf513))
* **apigateway:** support gateway and cdn https profiles ([33f3e17](https://github.com/roleyfoley/engine/commit/33f3e17a523e05c295fada2a89bb27b1ff3baa24))
* **apigw + waf:** separate logging enabled from logging profiles ([#1435](https://github.com/roleyfoley/engine/issues/1435)) ([c28ddd0](https://github.com/roleyfoley/engine/commit/c28ddd0f5328641241ee22794789b1d3bc97efd4))
* **base:** add object searching using a keys ([689cc34](https://github.com/roleyfoley/engine/commit/689cc348b6062eae3240daa1a9e5db4cd77c24ec))
* **console:** add dedicated cmk option for console sessions ([7f85bdc](https://github.com/roleyfoley/engine/commit/7f85bdccaa5c6451aab51a4e4fca086e11a9d57f))
* **console:** Update console support for encryption ([9e1610d](https://github.com/roleyfoley/engine/commit/9e1610d727e91b67199faa02a177b677b8ffb1b8))
* **containers:** ulimit configuration ([44392d9](https://github.com/roleyfoley/engine/commit/44392d91c390018ad2a4d3d835ad9b778723c6a0))
* **core:** extend policy profiles to occurence level control ([2b4ef77](https://github.com/roleyfoley/engine/commit/2b4ef77ffbb04dfa2ce9c0502ee01742923e0e19))
* **datafeed:** add deployment specifc indludes to prefix ([5a72166](https://github.com/roleyfoley/engine/commit/5a72166b5803583dcdb7b07b24e23953aa6853e4))
* **datafeed:** deploy specifc prefixes ([9fb8f9e](https://github.com/roleyfoley/engine/commit/9fb8f9ecfaa87ff1ceabe34641b80948c9fa0d97))
* **ec2:** volume encryption ([4cd1dfa](https://github.com/roleyfoley/engine/commit/4cd1dfa91144bd07a86afc1c2c3ccfea187ec0ac))
* **ecs:** add healthcheck support ([5c9cbc5](https://github.com/roleyfoley/engine/commit/5c9cbc52b0130b3f2cd38d978f264fc5b9c3f0f5))
* **ecs:** add hostname macro for containers ([a52f4cf](https://github.com/roleyfoley/engine/commit/a52f4cff3edbfe043ff38067268332e7393c6bb2))
* **ecs:** add lookup for ingress rules based on links for containers ([0d6c802](https://github.com/roleyfoley/engine/commit/0d6c8021065b725307fa38c70668009a988e34a0))
* **ecs:** add support for compute providers ([0ce39a7](https://github.com/roleyfoley/engine/commit/0ce39a77be39300cd181e11118ee3a312b8f2306))
* **ecs:** allow for fragment and image override in solution ([2ac4ad4](https://github.com/roleyfoley/engine/commit/2ac4ad4ae30f73e28fe5b6f4efd85f27738ffef4))
* **ecs:** fragment override and image override in solution ([f58b742](https://github.com/roleyfoley/engine/commit/f58b74291d401213423cbbc80461d4ab61a3aa24))
* **ecs:** placement constraint support ([31c8206](https://github.com/roleyfoley/engine/commit/31c82067e437576fb4c9d48c012206cbb89fd43e))
* **ecs:** support container image sourcing ([#1495](https://github.com/roleyfoley/engine/issues/1495)) ([06f4a00](https://github.com/roleyfoley/engine/commit/06f4a00cd4ea6d0eeec8f69feede60911ad9b3b5))
* **ecs:** support for efs volume mounts on ecs tasks ([3d2db45](https://github.com/roleyfoley/engine/commit/3d2db45af5ada53d2556f58bd4de090c5c7b973b))
* **efs:** support chroot based on mount points ([d6e1605](https://github.com/roleyfoley/engine/commit/d6e1605b301061318eebc819b37a6ddaa157c26c))
* **extensions:** Allow mutliple extensions ([0fd3c39](https://github.com/roleyfoley/engine/commit/0fd3c399f588fcf326a7fb4b42656565bc8592c8))
* **extensions:** convert existing fragments ([9531f69](https://github.com/roleyfoley/engine/commit/9531f6937b451f6a8cb1b5bf08cb11d3a3665453))
* **extensions:** support entrance extensions ([2122c8b](https://github.com/roleyfoley/engine/commit/2122c8b49537ac7244bc3d773a0efbec50e406b9))
* **externalnetwork:** intial external network support ([2a52bc3](https://github.com/roleyfoley/engine/commit/2a52bc3701fcf49b9588370b3ccc5c432d22397b))
* **externalnetwork+gateway:** vpn security profile ([2cc3441](https://github.com/roleyfoley/engine/commit/2cc34416ad247aa887d87a561726948d703096d3))
* **externalservice:** add support for endpoints on an external service ([0148788](https://github.com/roleyfoley/engine/commit/0148788cc8e4f32e7d8007708fd5b50eb592a546))
* **externalservice:** Attributes for external service endpoint ([464aa1e](https://github.com/roleyfoley/engine/commit/464aa1e4e9c6fc5cb4f53761f951c4f589228adb))
* **externalservice:** Networkacl support ([a93db78](https://github.com/roleyfoley/engine/commit/a93db78171180ef5c81234b489b675a99e2ecad5))
* **filetransfer:** security policy control ([275c738](https://github.com/roleyfoley/engine/commit/275c73826a1ad644a0604ff47fe5912caba076fe))
* **filetransfer:** support for a file transfer component with user integration ([67d40dc](https://github.com/roleyfoley/engine/commit/67d40dc50a849219c2c6f164d2cc36580c6c52b2))
* **fragment:** startup command setting for agent ([1709cca](https://github.com/roleyfoley/engine/commit/1709ccab910b0f0620f351803bc8dca1cb948ad4))
* **gateway:** destination port control ([8b7741e](https://github.com/roleyfoley/engine/commit/8b7741e0ba057b4e54484ba4b9868d286a20c464))
* **gateway:** destination port control for private services ([7c18532](https://github.com/roleyfoley/engine/commit/7c18532d0c010f6cf14ad369f178cf31672ddf9b))
* **gateway:** dns configuration support ([8099e9d](https://github.com/roleyfoley/engine/commit/8099e9d4b11927b1306dc1db3e34ff23bdb3a840))
* **gateway:** dynamic routing for private gw ([0e546fd](https://github.com/roleyfoley/engine/commit/0e546fd21341de0a9fdfb4978b5b5078b811f56f))
* **gateway:** private gateway ([5c9d0dd](https://github.com/roleyfoley/engine/commit/5c9d0ddb2a2c92a5144e6dfa36c277520f41962c))
* **gateway:** support for the router component as an engine ([5c3b73a](https://github.com/roleyfoley/engine/commit/5c3b73ae9020f6112af3b2e446ece80ed3603067))
* **globaldb:** intial support for global dbs ([#1325](https://github.com/roleyfoley/engine/issues/1325)) ([4cab2ad](https://github.com/roleyfoley/engine/commit/4cab2ada2d356c6a8a7e750e16de65e604053143))
* **hamlet-agent:** allow for agent level az tenant id ([32837eb](https://github.com/roleyfoley/engine/commit/32837eb6f691f651fa98593279034a09a309df7b))
* **jenkins:** add support for dind in hamlet agents ([e526e7e](https://github.com/roleyfoley/engine/commit/e526e7e0d9b2c2b55057593780eee9a6d551b63b))
* **jenkins:** add support for permanent ecs agents ([#1321](https://github.com/roleyfoley/engine/issues/1321)) ([05b8290](https://github.com/roleyfoley/engine/commit/05b8290f68ed8ed204b979da7d6c4f2c3733c31a))
* **lambda:** pull images from external source ([#1456](https://github.com/roleyfoley/engine/issues/1456)) ([dbc5a77](https://github.com/roleyfoley/engine/commit/dbc5a773c90a009a57ca3d1a9f1b7b32c8dbd786))
* **lb:** add static endpoint forwarding ([c72a615](https://github.com/roleyfoley/engine/commit/c72a6154f5137b5a33e4c8d0e1e258adc134955b))
* **lb:** Network load balancer TLS offload ([76f8a94](https://github.com/roleyfoley/engine/commit/76f8a94fb4919d35f65d55adacdb22195cb34e52))
* **lb:** WAF integration ([63d139b](https://github.com/roleyfoley/engine/commit/63d139b3d669796ba67c14e54014695afa59e688))
* **links:** incl. support for case-insensitive link direction ([95b62aa](https://github.com/roleyfoley/engine/commit/95b62aac0bf26006350aa8703973770b912b0903))
* **masterdata:** add additional rabbitmq port definitions for queuehost ([ae01e9b](https://github.com/roleyfoley/engine/commit/ae01e9beda66804363d84992dacd30deae2c6c04))
* **mobileapp:** OTA Support on CDN routes ([#1319](https://github.com/roleyfoley/engine/issues/1319)) ([4e85e17](https://github.com/roleyfoley/engine/commit/4e85e17c2edac7993ea7a0273699581dcb0e8f4f))
* **network:** flow log control ([69e3731](https://github.com/roleyfoley/engine/commit/69e373174053417a6b8b649fcc0089e3280ab055))
* **occurrence:** Setting namespaces for occurrence ([56345fe](https://github.com/roleyfoley/engine/commit/56345fec897e6949ef1c2365d1027c1fb74c6b37))
* **occurrence:** support caching of occurrences ([41d1183](https://github.com/roleyfoley/engine/commit/41d1183bcfb65dacf7fbd069e7081ebdd5c6a41b))
* support deployment document generation using group filters ([b905071](https://github.com/roleyfoley/engine/commit/b905071492ee72dd17bd00a978bf806cb25685ae))
* **openapi:** enable throttling settings on apigw ([f4cf8f0](https://github.com/roleyfoley/engine/commit/f4cf8f00ff0cba3fc767d01d232c2cfe3601e6ee))
* **privateservice:** intial support for private services ([#1330](https://github.com/roleyfoley/engine/issues/1330)) ([1f2169b](https://github.com/roleyfoley/engine/commit/1f2169baaec821e3ffe3894477eace3f689adbc4))
* **queuehost:** initial definition ([a884bb2](https://github.com/roleyfoley/engine/commit/a884bb26300e4796e64e807483ad39097f097134))
* **registry:** support for mutli region registry ([6df845e](https://github.com/roleyfoley/engine/commit/6df845e5afeaacbcde9573decd75f2d0c6837275))
* **router:** adds initial support for the router component ([9ecc76e](https://github.com/roleyfoley/engine/commit/9ecc76e189f809036649c398dd5d24f22e7a7733))
* **router:** make BGP ASN mandatory ([b757303](https://github.com/roleyfoley/engine/commit/b757303eee35369e5518f791980f2499334122fe))
* **router:** static route support ([574a030](https://github.com/roleyfoley/engine/commit/574a030d2d7a5b7be7ce35b501b0d9d321b833ac))
* **s3:** account level S3 Encryption ([1264ff9](https://github.com/roleyfoley/engine/commit/1264ff904fef4c882548291ff728aa9ad4e97778))
* **s3:** add configuration support s3 Encryption ([282aa2f](https://github.com/roleyfoley/engine/commit/282aa2f94dbeda66a34aec4e08a51eb96689847a))
* **s3:** baseline s3 encryption permissions ([214c030](https://github.com/roleyfoley/engine/commit/214c030cedf355ca044f3fec52e2ca2a645df9cb))
* **schema:** add required property to jsonschemas ([#1367](https://github.com/roleyfoley/engine/issues/1367)) ([f5f98fb](https://github.com/roleyfoley/engine/commit/f5f98fb9c1a9cfc8aff195017a1c36a90aa1d6d4))
* Network rule component configuration ([fda7396](https://github.com/roleyfoley/engine/commit/fda7396730e87e1f404d08c77c336fea83f3eab8))
* **schema:** added subsets for reference data and component schema ([b3db31d](https://github.com/roleyfoley/engine/commit/b3db31d0a1bb64aa08caea12c0013ffa4488e22c))
* **schema:** default output - schema ([d384f90](https://github.com/roleyfoley/engine/commit/d384f905e2ea6596810168fc1ff3305c809d0c2b))
* **secretstore:** new component type - secretstore ([7b93c76](https://github.com/roleyfoley/engine/commit/7b93c76a152ed734068cc2f60767130ae55fc00c))
* **secretstore:** update configuration and make it shareable ([#1484](https://github.com/roleyfoley/engine/issues/1484)) ([d1f977a](https://github.com/roleyfoley/engine/commit/d1f977ae599f661e39968331d56c5052a01a3c11))
* **testcases:** add additional output suffix types. ([e79b0f2](https://github.com/roleyfoley/engine/commit/e79b0f202dee1a7793633238d96e451640318017))
* **userpool:** Add Encryption schema to client secrets ([dcc0571](https://github.com/roleyfoley/engine/commit/dcc0571ece75b92d8ee6c5a83bb1f90aae1c6c6e))
* "Account" and fixed build scope ([#1402](https://github.com/roleyfoley/engine/issues/1402)) ([258e32b](https://github.com/roleyfoley/engine/commit/258e32b8ac857806997f1b12250461605d66602c))
* account inbound ses configuration ([ad8e377](https://github.com/roleyfoley/engine/commit/ad8e3775caa3f641e5ab5dc966334ad52e7941ae))
* add databucket replication attributes ([#1411](https://github.com/roleyfoley/engine/issues/1411)) ([2eaf5d5](https://github.com/roleyfoley/engine/commit/2eaf5d5a94f46dbf3ecdd8fad36bc2476243f7e0))
* add deployment component attributes ([d88431c](https://github.com/roleyfoley/engine/commit/d88431c19daf808f576df59097955d4d78824810))
* add deployment groups for unit and level control ([23a89b0](https://github.com/roleyfoley/engine/commit/23a89b05fd885e56031e53bca37ca987c14b93a4))
* add engine attr to containerhost ([aff09a5](https://github.com/roleyfoley/engine/commit/aff09a51744ccf487f897d0bca07aac135968e1b))
* Add engine support for layers ([126fbd3](https://github.com/roleyfoley/engine/commit/126fbd3a361b4740cf4c54f029cfc1f0a5ae9700))
* add host from network util ([cab414c](https://github.com/roleyfoley/engine/commit/cab414c8348f49077796080c275e918dc167aecc))
* add operations and provider to mgmt ([72703d9](https://github.com/roleyfoley/engine/commit/72703d95848b9a41f4c73de676f77d76298b30fb))
* add policy to core component config ([ce15bb5](https://github.com/roleyfoley/engine/commit/ce15bb547e44f2d48d9c8d95cce36cd42e3fc8f1))
* add processor profiles ([05da8ee](https://github.com/roleyfoley/engine/commit/05da8eedaa0bf903a74530f9c0d49ab6100868c2))
* add reference definitions for profiles ([9d62654](https://github.com/roleyfoley/engine/commit/9d62654f1b5d8a4653ebd2d8b6cb28bf1aa5f40c))
* add resource labels to support resourceSets in deployment groups ([23e2c32](https://github.com/roleyfoley/engine/commit/23e2c32b93c9dd21f68bc92846bb38b7d4c747c1))
* add scenario loading through blueprint ([422bd43](https://github.com/roleyfoley/engine/commit/422bd4309c68df785063a83312156e2e0a737b2d))
* add scenario profile reference type ([45af67e](https://github.com/roleyfoley/engine/commit/45af67e241d69eb6cf7f3e81a8e5c410c6e7cc9e))
* add service role provisioing to account level ([ecfbcb4](https://github.com/roleyfoley/engine/commit/ecfbcb4797275461dc969ae79352b0883965906d))
* add service role reference ([41dba2a](https://github.com/roleyfoley/engine/commit/41dba2a1c3dac83732a8e0c2ed3065422440ff6a))
* add support for token validity expressions ([#1409](https://github.com/roleyfoley/engine/issues/1409)) ([0e128a7](https://github.com/roleyfoley/engine/commit/0e128a7be5015c3d687f39f9419fc30445bb0891))
* allow setting encryption scheme for attributes ([6507868](https://github.com/roleyfoley/engine/commit/6507868af2608f09f31b3f7b53272a8a3fed6cf9))
* API gateway error format control ([8f9eb3a](https://github.com/roleyfoley/engine/commit/8f9eb3a3c10149174dc512f997b65c087775c824))
* aws ecs account settings ([44f8f3e](https://github.com/roleyfoley/engine/commit/44f8f3e62ef1d035288b33266d8ee64051ba2420))
* Bucket cleanup optional when copying files ([07cccf0](https://github.com/roleyfoley/engine/commit/07cccf0c6ad50ba1dc080d32644cdc2a6bfdb2d7))
* bug-feature templates for issues ([d86b8ab](https://github.com/roleyfoley/engine/commit/d86b8abfe8ca94071dbe8160bf505303ea6cfa69))
* component deployment attributes ([be4865f](https://github.com/roleyfoley/engine/commit/be4865fa2602173bddbab72ee9c01df8505225d9))
* consolidate level clients in line with deployment groups ([f0e3dd5](https://github.com/roleyfoley/engine/commit/f0e3dd56b0b522c275063a7ad04f830c9dbf9bf7))
* Container support for network profiles ([90dc7b6](https://github.com/roleyfoley/engine/commit/90dc7b6a8d0c7fe04f930a6803486ebd5ce4f041))
* define layers in shared provider ([358a034](https://github.com/roleyfoley/engine/commit/358a034f5afd917fcadcc66928e7dc22413f398a))
* deployment mode and group refernce ([8f1c8c3](https://github.com/roleyfoley/engine/commit/8f1c8c3a258d3f81a0649079ba6a8ec20497f8b8))
* document set support ([ab6dda4](https://github.com/roleyfoley/engine/commit/ab6dda4b9047ea5cde71177f0e63a0100f69d343))
* dynamic model loading and scopes ([d5062b7](https://github.com/roleyfoley/engine/commit/d5062b75203ecaa2c99d593935ddbea0d0e6656c))
* fragment migration to extensions ([6fef804](https://github.com/roleyfoley/engine/commit/6fef804b3a8407ebb479e318d13596aeb7f31618))
* Generic check for type in authentication header ([137fc60](https://github.com/roleyfoley/engine/commit/137fc60b56fb53e6fa91055d435c53475327265d))
* globaldb secondary indexes ([#1507](https://github.com/roleyfoley/engine/issues/1507)) ([86ac1c0](https://github.com/roleyfoley/engine/commit/86ac1c0c108d87399a8c69ecb90c7a5a8c0ece84))
* hamlet info view ([913d021](https://github.com/roleyfoley/engine/commit/913d021ad82b5ae2079b15733d76b9805405a706))
* manage one off instance failures ([aed0a8d](https://github.com/roleyfoley/engine/commit/aed0a8d2e45cfdd3f0491a466edbe1c09d789575))
* management contract generation ([5327a02](https://github.com/roleyfoley/engine/commit/5327a027bbe1f0519582ecaa603e6902423d7ce0))
* MTA component ([493cd3b](https://github.com/roleyfoley/engine/commit/493cd3b2426f7845cf285a53d86b283ff3e5786c))
* network profiles ([2ce49fe](https://github.com/roleyfoley/engine/commit/2ce49fe403ee954912a735295df612d2c166f627))
* os patching in solution config ([cd698d5](https://github.com/roleyfoley/engine/commit/cd698d5b4f485ce73fc53c45b582b6ba8806472c))
* s3 sync exclude support ([9120899](https://github.com/roleyfoley/engine/commit/9120899186efc06c0dd53e50b5244f646376bfad))
* semver support ([#1434](https://github.com/roleyfoley/engine/issues/1434)) ([016cd80](https://github.com/roleyfoley/engine/commit/016cd80a1998e70cad1391c55a7691fedaca018e))
* set container level auth method for hamlet agent ([24489a0](https://github.com/roleyfoley/engine/commit/24489a07b8673321a22bcfd2988e21a89369b544))
* set default deployment group for all components ([d4301e1](https://github.com/roleyfoley/engine/commit/d4301e1e7291e44b709643004020cafecbabf4e5))
* splitting out container components ([49a7ab1](https://github.com/roleyfoley/engine/commit/49a7ab10ee40580a0e1a99bbefb35a2f9b47df64))
* **userpool:** control oauth on clients ([c550e50](https://github.com/roleyfoley/engine/commit/c550e50ae4f4c8a03db65417e36aba884f9d6e7d))
* **waf:** add waf logging profiles ([d431a8a](https://github.com/roleyfoley/engine/commit/d431a8aa29cdb88abc2a5d40f0b0c7ece2f1e108))
* support deployment group filtering on occurrences ([ed397e4](https://github.com/roleyfoley/engine/commit/ed397e4b8cbac5f30c52a81a123fb852b2c96d78))
* support for centralised service resources ([cd762b8](https://github.com/roleyfoley/engine/commit/cd762b8fc68687b4ceeee529f9f838d171d09911))
* template control per api gateway status ([771a37d](https://github.com/roleyfoley/engine/commit/771a37d22c1dfd94d84af755947a246fa0969eaa))
* tier based network lookup ([#1359](https://github.com/roleyfoley/engine/issues/1359)) ([6e9f710](https://github.com/roleyfoley/engine/commit/6e9f7107b0cdbf3454b8a05c11a908a1e1ccdfd9))
* update format for deployment groups to incldue name/id ([66faa02](https://github.com/roleyfoley/engine/commit/66faa02f165f13e44bb414c82566a7c2a8267843))
* views for blueprint and schema ([7ae367e](https://github.com/roleyfoley/engine/commit/7ae367ecd57b8e52f53fbe626d7e8f0b5caa81c0))


### BREAKING CHANGES

* any calls to macro invocations for scenarios will now
be to modules, the scenarioProfile has also been removed, instead the
scenario configuration is provided directly to a layer
* **ecs:** this also removes the existing ComputeProvider option
on the ECS component in favour of a more configurable approach
* The scenario format and loading process has now changed
to support this
* All Component macros now need to include an entrance as
part of their name to allow for different macros based on entrance



# [7.0.0](https://github.com/roleyfoley/engine/compare/v6.0.0...v7.0.0) (2020-04-25)



# [6.0.0](https://github.com/roleyfoley/engine/compare/v5.4.0...v6.0.0) (2019-09-13)



# [5.4.0](https://github.com/roleyfoley/engine/compare/v5.3.1...v5.4.0) (2019-03-06)



## [5.3.1](https://github.com/roleyfoley/engine/compare/v5.3.0...v5.3.1) (2018-11-16)



# [5.3.0](https://github.com/roleyfoley/engine/compare/v5.3.0-rc1...v5.3.0) (2018-11-15)



# [5.3.0-rc1](https://github.com/roleyfoley/engine/compare/v5.2.0-rc3...v5.3.0-rc1) (2018-10-23)



# [5.2.0-rc3](https://github.com/roleyfoley/engine/compare/v5.2.0-rc2...v5.2.0-rc3) (2018-07-12)



# [5.2.0-rc2](https://github.com/roleyfoley/engine/compare/v5.2.0-rc1...v5.2.0-rc2) (2018-06-21)



# [5.2.0-rc1](https://github.com/roleyfoley/engine/compare/v5.1.0...v5.2.0-rc1) (2018-06-19)



# [5.1.0](https://github.com/roleyfoley/engine/compare/v4.3.10...v5.1.0) (2018-05-22)



## [4.3.10](https://github.com/roleyfoley/engine/compare/v4.3.9...v4.3.10) (2017-09-17)



## [4.3.9](https://github.com/roleyfoley/engine/compare/v4.3.8...v4.3.9) (2017-05-13)



## [4.3.8](https://github.com/roleyfoley/engine/compare/v4.3.7...v4.3.8) (2017-05-10)



## [4.3.7](https://github.com/roleyfoley/engine/compare/v4.3.6...v4.3.7) (2017-05-08)



## [4.3.6](https://github.com/roleyfoley/engine/compare/v4.3.5...v4.3.6) (2017-05-07)



## [4.3.5](https://github.com/roleyfoley/engine/compare/v4.3.4...v4.3.5) (2017-05-04)



## [4.3.4](https://github.com/roleyfoley/engine/compare/v4.3.3...v4.3.4) (2017-05-04)



## [4.3.3](https://github.com/roleyfoley/engine/compare/v4.3.2...v4.3.3) (2017-05-04)



## [4.3.2](https://github.com/roleyfoley/engine/compare/v4.3.1...v4.3.2) (2017-04-28)



## [4.3.1](https://github.com/roleyfoley/engine/compare/v4.1.1...v4.3.1) (2017-03-26)



## 4.1.1 (2017-02-03)



