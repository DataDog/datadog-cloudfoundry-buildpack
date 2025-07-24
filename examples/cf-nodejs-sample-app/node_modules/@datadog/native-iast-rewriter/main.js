/**
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache-2.0 License.
 * This product includes software developed at Datadog (https://www.datadoghq.com/). Copyright 2022 Datadog, Inc.
 **/
'use strict'
const { getPrepareStackTrace } = require('./js/stack-trace/')
const { cacheRewrittenSourceMap } = require('./js/source-map')

class DummyRewriter {
  rewrite (code, file) {
    return {
      content: code
    }
  }

  csiMethods () {
    return []
  }
}

let NativeRewriter
class CacheRewriter {
  constructor (config) {
    if (NativeRewriter) {
      this.nativeRewriter = new NativeRewriter(config)
    } else {
      this.nativeRewriter = new DummyRewriter()
    }
  }

  rewrite (code, file) {
    const response = this.nativeRewriter.rewrite(code, file)
    cacheRewrittenSourceMap(file, response.content)
    return response
  }

  csiMethods () {
    return this.nativeRewriter.csiMethods()
  }
}

function getRewriter () {
  try {
    const iastRewriter = require('./wasm/wasm_iast_rewriter')
    NativeRewriter = iastRewriter.Rewriter
    return CacheRewriter
  } catch (e) {
    return DummyRewriter
  }
}

module.exports = {
  Rewriter: getRewriter(),
  DummyRewriter,
  getPrepareStackTrace: getPrepareStackTrace
}
