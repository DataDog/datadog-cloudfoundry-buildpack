# Changelog

## 4.34.0 / 2022-11-14

* [Added] Add support for CAPI metadata and DCA tags injection. See [#136](https://github.com/DataDog/datadog-cloudfoundry-buildpack/pull/136).
  * Requires Agent BOSH Release [4.12.0](https://github.com/DataDog/datadog-agent-boshrelease/releases/tag/4.12.0) or higher in the host VM.
* [Added] Set hostname to container hostname when 'DD_ENABLE_CHECKS' is enabled. See [#143](https://github.com/DataDog/datadog-cloudfoundry-buildpack/pull/143).
* [Added] Bump agent version to 7.40.1. [read more about it here](https://github.com/DataDog/datadog-agent/blob/master/CHANGELOG.rst#7401--6401)
* [Fixed] Fix `KeyError` in create_logs_config python script. See [#140](https://github.com/DataDog/datadog-cloudfoundry-buildpack/pull/140).
* [Fixed] Fix `DD_TAGS` format issues. See [#135](https://github.com/DataDog/datadog-cloudfoundry-buildpack/pull/135).

## 4.33.0 / 2022-08-03

* [Added] Bump agent version to 7.37.1, [read more about it here](https://github.com/DataDog/datadog-agent/blob/master/CHANGELOG.rst#7371--6371)

## 4.32.0 / 2022-06-09

* [Added] Bump agent version to 7.36.1, [read more about it here](https://github.com/DataDog/datadog-agent/blob/master/CHANGELOG.rst#7361--6361)
* [Changed] Use VM hostname for logs, traces and metrics. See [#129](https://github.com/DataDog/datadog-cloudfoundry-buildpack/pull/129).

## 4.31.0 / 2022-04-14

* [Added] Bump agent version to 7.35.1, [read more about it here](https://github.com/DataDog/datadog-agent/blob/master/CHANGELOG.rst#7351--6351)

## 4.30.0 / 2022-02-07

* [Added] Bump agent version to 7.33.0, [read more about it here](https://github.com/DataDog/datadog-agent/blob/master/CHANGELOG.rst#7330--6330)

## 4.29.0 / 2021-12-22

* [Added] Bump agent version to 7.32.4, [read more about it here](https://github.com/DataDog/datadog-agent/blob/master/CHANGELOG.rst#7324--6324)

## 4.28.0 / 2021-12-20

* [Added] Bump agent version to 7.32.3, [read more about it here](https://github.com/DataDog/datadog-agent/blob/master/CHANGELOG.rst#7323--6323)

## 4.27.0 / 2021-12-13

* [Added] Bump agent version to 7.32.2, [read more about it here](https://github.com/DataDog/datadog-agent/blob/master/CHANGELOG.rst#7322--6322)
* [Fixed] Fix startup issues when using sidecars. See [#120](https://github.com/DataDog/datadog-cloudfoundry-buildpack/pull/120). Thanks [martinpfeifer](https://github.com/martinpfeifer).

## 4.26.0 / 2021-11-29

* [Added] Bump agent version to 7.32.1, [read more about it here](https://github.com/DataDog/datadog-agent/blob/master/CHANGELOG.rst#7321--6321)

## 4.25.0 / 2021-09-22

* [Added] Bump agent version to 7.31.0, [read more about it here](https://github.com/DataDog/datadog-agent/blob/master/CHANGELOG.rst#7310--6310)

## 4.24.0 / 2021-08-16

* [Added] Bump agent version to 7.30.0, [read more about it here](https://github.com/DataDog/datadog-agent/blob/master/CHANGELOG.rst#7300--6300)

## 4.23.0 / 2021-07-23

* [Fixed] Avoid losing log lines when app sparsely writes to STDOUT. See [#112](https://github.com/DataDog/datadog-cloudfoundry-buildpack/pull/112).
* [Fixed] Fix check of `LOGS_CONFIG` env var. See [#111](https://github.com/DataDog/datadog-cloudfoundry-buildpack/pull/111).
* [Fixed] Install Datadog bits in hidden folder to avoid interfering with some buildpack detection mechanism. See [#109](https://github.com/DataDog/datadog-cloudfoundry-buildpack/pull/109).

## 4.22.0 / 2021-04-28

* [Added] Add ability to keep or suppress agent logs from cf logs. Suppress by default. See [#108](https://github.com/DataDog/datadog-cloudfoundry-buildpack/pull/108).
* [Fixed] Fix reading duplicate logs configuration. See [#107](https://github.com/DataDog/datadog-cloudfoundry-buildpack/pull/107).
* [Fixed] Prevent buildpack from blocking application startup when verbose application starts. See [#105](https://github.com/DataDog/datadog-cloudfoundry-buildpack/pull/105).
* [Fixed] Stop counting buildpack agent as IoT agent. See [#100](https://github.com/DataDog/datadog-cloudfoundry-buildpack/pull/100).
* [Added] Bump agent version to 7.27.0, [read more about it here](https://github.com/DataDog/datadog-agent/blob/master/CHANGELOG.rst#7270--6270)

## 4.21.0 / 2021-04-06

* [Added] Add `CF_INSTANCE_IP` environment variable as host tag. See [#102](https://github.com/DataDog/datadog-cloudfoundry-buildpack/pull/102).
* [Fixed] Stop agent processes when main app process exits. See [#97](https://github.com/DataDog/datadog-cloudfoundry-buildpack/pull/97).
* [Added] Bump agent version to 7.26.0, [read more about it here](https://github.com/DataDog/datadog-agent/blob/master/CHANGELOG.rst#7260--6260)

## 4.20.0 / 2021-01-21

* [Added] Bump agent version to 7.25.0, [read more about it here](https://github.com/DataDog/datadog-agent/blob/master/CHANGELOG.rst#7250--6250)

## 4.19.0 / 2020-12-14

* [Added] Bump agent version to 7.24.0, [read more about it here](https://github.com/DataDog/datadog-agent/blob/master/CHANGELOG.rst#7240--6240)

## 4.18.0 / 2020-10-14

* [Added] Bump agent version to 7.23.0, [read more about it here](https://github.com/DataDog/datadog-agent/blob/master/CHANGELOG.rst#7230--6230)

## 4.17.0 / 2020-08-31

* [Added] Bump agent version to 7.22.0, [read more about it here](https://github.com/DataDog/datadog-agent/blob/master/CHANGELOG.rst#7220--6220)

## 4.16.0 / 2020-07-23

* [Added] Bump agent version to 7.21.1, [read more about it here](https://github.com/DataDog/datadog-agent/blob/master/CHANGELOG.rst#7211)

## 4.15.0 / 2020-06-17

* [Added] Bump agent version to 7.20.2, [read more about it here](https://github.com/DataDog/datadog-agent/blob/master/CHANGELOG.rst#7202)

## 4.14.0 / 2020-05-06

* [Added] Bump agent version to 7.19.1. See [#87](https://github.com/DataDog/datadog-cloudfoundry-buildpack/pull/87).
* [Fixed] Fix instance_index missing if instance_index is 0. See [#86](https://github.com/DataDog/datadog-cloudfoundry-buildpack/pull/86).
