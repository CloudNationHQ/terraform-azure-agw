# Changelog

## [1.5.0](https://github.com/CloudNationHQ/terraform-azure-agw/compare/v1.4.3...v1.5.0) (2025-12-22)


### Features

* **deps:** bump github.com/cloudnationhq/az-cn-go-validor in /tests ([#49](https://github.com/CloudNationHQ/terraform-azure-agw/issues/49)) ([41e0436](https://github.com/CloudNationHQ/terraform-azure-agw/commit/41e04360a1e519a4709b1b9f20fe19a94d9dac2c))
* **deps:** bump github.com/cloudnationhq/az-cn-go-validor in /tests ([#55](https://github.com/CloudNationHQ/terraform-azure-agw/issues/55)) ([34eb50e](https://github.com/CloudNationHQ/terraform-azure-agw/commit/34eb50e9cb23ed08606961d3808ecb1385d3d5c7))
* **deps:** bump github.com/gruntwork-io/terratest in /tests ([#43](https://github.com/CloudNationHQ/terraform-azure-agw/issues/43)) ([09ba4a4](https://github.com/CloudNationHQ/terraform-azure-agw/commit/09ba4a4d205219b3a45897c4c31c94d37f5d2955))
* **deps:** bump github.com/ulikunitz/xz from 0.5.10 to 0.5.14 in /tests ([#47](https://github.com/CloudNationHQ/terraform-azure-agw/issues/47)) ([4ad9c7b](https://github.com/CloudNationHQ/terraform-azure-agw/commit/4ad9c7b5b417bcaf5ff9daab176265a160ae715f))
* **deps:** bump golang.org/x/crypto from 0.36.0 to 0.45.0 in /tests ([#50](https://github.com/CloudNationHQ/terraform-azure-agw/issues/50)) ([057ec6c](https://github.com/CloudNationHQ/terraform-azure-agw/commit/057ec6ccd3097d5de6ae4ff02b98c8dd3e86f2a9))


### Bug Fixes

* default null value for min_protocol_version ([#56](https://github.com/CloudNationHQ/terraform-azure-agw/issues/56)) ([16fc9b2](https://github.com/CloudNationHQ/terraform-azure-agw/commit/16fc9b27935e735c811b2e76fb45b3265e1984f3))

## [1.4.3](https://github.com/CloudNationHQ/terraform-azure-agw/compare/v1.4.2...v1.4.3) (2025-12-10)


### Bug Fixes

* Probe host parameter not effective  ([#52](https://github.com/CloudNationHQ/terraform-azure-agw/issues/52)) ([fab6b07](https://github.com/CloudNationHQ/terraform-azure-agw/commit/fab6b073d6a1a0866e9dd47e52d7603d6afd7e58))

## [1.4.2](https://github.com/CloudNationHQ/terraform-azure-agw/compare/v1.4.1...v1.4.2) (2025-08-08)


### Bug Fixes

* make capacity optional,  ([#45](https://github.com/CloudNationHQ/terraform-azure-agw/issues/45)) ([8c592d3](https://github.com/CloudNationHQ/terraform-azure-agw/commit/8c592d31c7ac287cedcca415a9670de8b43233bd))

## [1.4.1](https://github.com/CloudNationHQ/terraform-azure-agw/compare/v1.4.0...v1.4.1) (2025-02-24)


### Bug Fixes

* fix hierarchy backend pools ([#36](https://github.com/CloudNationHQ/terraform-azure-agw/issues/36)) ([064c4d8](https://github.com/CloudNationHQ/terraform-azure-agw/commit/064c4d820e3b5f3c3486d330676c2b6994722bdf))

## [1.4.0](https://github.com/CloudNationHQ/terraform-azure-agw/compare/v1.3.3...v1.4.0) (2025-02-18)


### Features

* add some missing properties ([#33](https://github.com/CloudNationHQ/terraform-azure-agw/issues/33)) ([ebe3e7b](https://github.com/CloudNationHQ/terraform-azure-agw/commit/ebe3e7b48b61c7a06bf07862703fbca35667d9db))


### Bug Fixes

* remove redundant loop listeners ([#34](https://github.com/CloudNationHQ/terraform-azure-agw/issues/34)) ([ef89a74](https://github.com/CloudNationHQ/terraform-azure-agw/commit/ef89a746d7ad6dace21ad6164582383518e2ace1))

## [1.3.3](https://github.com/CloudNationHQ/terraform-azure-agw/compare/v1.3.2...v1.3.3) (2025-02-18)


### Bug Fixes

* remove redundant fqdns property ([#31](https://github.com/CloudNationHQ/terraform-azure-agw/issues/31)) ([4da048f](https://github.com/CloudNationHQ/terraform-azure-agw/commit/4da048f3e9ac5acf7b378a561a0886973ce5820c))

## [1.3.2](https://github.com/CloudNationHQ/terraform-azure-agw/compare/v1.3.1...v1.3.2) (2025-02-18)


### Bug Fixes

* fix several properties to be optional and corrected some usages ([#29](https://github.com/CloudNationHQ/terraform-azure-agw/issues/29)) ([ae6d161](https://github.com/CloudNationHQ/terraform-azure-agw/commit/ae6d161803419a9741fdf61b79d19b56f10e98aa))

## [1.3.1](https://github.com/CloudNationHQ/terraform-azure-agw/compare/v1.3.0...v1.3.1) (2025-02-13)


### Bug Fixes

* move backend http settings up one level in hierarchy ([#27](https://github.com/CloudNationHQ/terraform-azure-agw/issues/27)) ([39316a1](https://github.com/CloudNationHQ/terraform-azure-agw/commit/39316a16251705a859572986c29ee156d1d3b904))

## [1.3.0](https://github.com/CloudNationHQ/terraform-azure-agw/compare/v1.2.0...v1.3.0) (2025-02-12)


### Features

* add network interface backend pool association support ([#26](https://github.com/CloudNationHQ/terraform-azure-agw/issues/26)) ([2fdcbe9](https://github.com/CloudNationHQ/terraform-azure-agw/commit/2fdcbe9279ab98c9f8ef94ce75e3360f400bad8d))
* **deps:** bump github.com/gruntwork-io/terratest in /tests ([#25](https://github.com/CloudNationHQ/terraform-azure-agw/issues/25)) ([d32089e](https://github.com/CloudNationHQ/terraform-azure-agw/commit/d32089e0a5916051c4100fa594ba6c48fad51afe))


### Bug Fixes

* make backend_settings,probe and backend_pools fully optional, add missing properties ([#22](https://github.com/CloudNationHQ/terraform-azure-agw/issues/22)) ([9889f84](https://github.com/CloudNationHQ/terraform-azure-agw/commit/9889f849ff02cfce66fbff2920744a31f987c4c0))

## [1.2.0](https://github.com/CloudNationHQ/terraform-azure-agw/compare/v1.1.0...v1.2.0) (2025-01-29)


### Features

* updated identity(optional), ssl_cert (optional) ([#19](https://github.com/CloudNationHQ/terraform-azure-agw/issues/19)) ([4fd04fe](https://github.com/CloudNationHQ/terraform-azure-agw/commit/4fd04feb767777cfee2f1df2aed4377c41bc34e1))

## [1.1.0](https://github.com/CloudNationHQ/terraform-azure-agw/compare/v1.0.0...v1.1.0) (2025-01-29)


### Features

* **deps:** bump github.com/gruntwork-io/terratest in /tests ([#14](https://github.com/CloudNationHQ/terraform-azure-agw/issues/14)) ([8f7a9b4](https://github.com/CloudNationHQ/terraform-azure-agw/commit/8f7a9b43174db1478bc22aeb63a3b064c78bc0ea))
* **deps:** bump golang.org/x/crypto from 0.29.0 to 0.31.0 in /tests ([#16](https://github.com/CloudNationHQ/terraform-azure-agw/issues/16)) ([1d69aa3](https://github.com/CloudNationHQ/terraform-azure-agw/commit/1d69aa3fddf4ce64b3cf965f22d0d5fb5c5cf100))
* **deps:** bump golang.org/x/net from 0.31.0 to 0.33.0 in /tests ([#17](https://github.com/CloudNationHQ/terraform-azure-agw/issues/17)) ([669a15c](https://github.com/CloudNationHQ/terraform-azure-agw/commit/669a15c141a4e2dac768bf7cd0f9d0e4e76d3fb7))

## 1.0.0 (2024-11-29)


### Features

* add initial resources ([#2](https://github.com/CloudNationHQ/terraform-azure-agw/issues/2)) ([6feea34](https://github.com/CloudNationHQ/terraform-azure-agw/commit/6feea3497af35a044464df5424c7dd3ccdbcbc07))
