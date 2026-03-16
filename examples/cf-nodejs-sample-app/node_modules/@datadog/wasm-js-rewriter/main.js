/**
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache-2.0 License.
 * This product includes software developed at Datadog (https://www.datadoghq.com/). Copyright 2022 Datadog, Inc.
 **/
'use strict'
const { getPrepareStackTrace, kSymbolPrepareStackTrace } = require('./js/stack-trace/')
const { cacheRewrittenSourceMap, getOriginalPathAndLineFromSourceMap } = require('./js/source-map')
const getNameAndVersion = require('./js/module-details')
const yaml = require('js-yaml')

class DummyRewriter {
  rewrite (code, file, passes, moduleName, moduleVersion) {
    return {
      content: code
    }
  }

  csiMethods () {
    return []
  }
}

let NativeRewriter

class NonCacheRewriter {
  constructor (config) {
    if (NativeRewriter) {
      this.nativeRewriter = new NativeRewriter(config)
      this.setLogger(config)
    } else {
      this.nativeRewriter = new DummyRewriter()
    }
    if (config?.orchestrion) {
      const { instrumentations } = yaml.load(config.orchestrion)
      this.orchestrionModules = new Set(instrumentations.map((i) => i.module_name))
    }
  }

  rewrite (code, file, passes) {
    let moduleName
    let moduleVersion
    if (passes.includes('orchestrion')) {
      const details = getNameAndVersion(file)
      moduleName = details.name
      moduleVersion = details.version
      if (!this.orchestrionModules.has(moduleName)) {
        passes.splice(passes.indexOf('orchestrion'), 1)
      }
    }
    if (passes.length === 0) {
      return { content: code }
    }
    const response = this.nativeRewriter.rewrite(code, file, passes, moduleName, moduleVersion)

    // rewrite returns an empty content when for the 'notmodified' status
    if (response?.metrics?.status === 'notmodified') {
      response.content = code
    }

    return response
  }

  csiMethods () {
    return this.nativeRewriter.csiMethods()
  }

  setLogger (config) {
    if (config && (config.logger || config.logLevel)) {
      this.logger = config.logger || console
      const logLevel = config.logLevel || 'ERROR'
      try {
        this.nativeRewriter.setLogger(this.logger, logLevel)
      } catch (e) {
        this.logError(e)
      }
    }
  }

  logError (e) {
    this.logger?.error?.(e)
  }
}

class CacheRewriter extends NonCacheRewriter {
  rewrite (code, file, passes) {
    const response = super.rewrite(code, file, passes)

    try {
      const { metrics, content } = response
      if (metrics?.status === 'modified') {
        cacheRewrittenSourceMap(file, content)
      }
    } catch (e) {
      this.logError(e)
    }

    return response
  }
}

function getRewriter (withoutCache = false) {
  try {
    const rewriter = require('./wasm/wasm_js_rewriter')

    NativeRewriter = rewriter.Rewriter
    return withoutCache ? NonCacheRewriter : CacheRewriter
  } catch (e) {
    return DummyRewriter
  }
}

module.exports = {
  Rewriter: getRewriter(),
  NonCacheRewriter: getRewriter(true),
  DummyRewriter,
  getPrepareStackTrace,
  getOriginalPathAndLineFromSourceMap,
  kSymbolPrepareStackTrace,
  cacheRewrittenSourceMap
}
