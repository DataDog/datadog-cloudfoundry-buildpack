'use strict'
const path = require('path')
const fs = require('fs')
const { SourceMap } = require('./node_source_map')
const SOURCE_MAP_LINE_START = '//# sourceMappingURL='
const SOURCE_MAP_INLINE_LINE_START = '//# sourceMappingURL=data:application/json;base64,'
const rewrittenSourceMapsCache = new Map()

function generateSourceMapFromFileContent (fileContent, filePath) {
  const fileLines = fileContent.trim().split('\n')
  const lastLine = fileLines[fileLines.length - 1]
  let rawSourceMap
  if (lastLine.indexOf(SOURCE_MAP_INLINE_LINE_START) === 0) {
    const sourceMapInBase64 = lastLine.substring(SOURCE_MAP_INLINE_LINE_START.length)
    rawSourceMap = Buffer.from(sourceMapInBase64, 'base64').toString('utf8')
  } else if (lastLine.indexOf(SOURCE_MAP_LINE_START) === 0) {
    let sourceMappingURL = lastLine.substring(SOURCE_MAP_LINE_START.length)
    if (sourceMappingURL) {
      sourceMappingURL = path.join(filePath, sourceMappingURL)
      rawSourceMap = fs.readFileSync(sourceMappingURL).toString()
    }
  }
  if (rawSourceMap) {
    return new SourceMap(JSON.parse(rawSourceMap))
  }
}

function cacheRewrittenSourceMap (filename, fileContent) {
  const sm = generateSourceMapFromFileContent(fileContent, getFilePathFromName(filename))
  rewrittenSourceMapsCache.set(filename, sm)
}

function getFilePathFromName (filename) {
  const filenameParts = filename.split(path.sep)
  filenameParts.pop()
  return filenameParts.join(path.sep)
}

function getSourcePathAndLineFromSourceMaps (filename, line, column = 0) {
  try {
    const sourceMap = rewrittenSourceMapsCache.get(filename)
    if (sourceMap) {
      const filePath = getFilePathFromName(filename)
      const { originalSource, originalLine, originalColumn } = sourceMap.findEntry(line - 1, column - 1)
      return {
        path: path.join(filePath, originalSource),
        line: originalLine + 1,
        column: originalColumn + 1
      }
    }
  } catch (e) {
    // can not read the source maps, return original path and line
  }
  return { path: filename, line, column }
}

module.exports = {
  getSourcePathAndLineFromSourceMaps,
  cacheRewrittenSourceMap
}
