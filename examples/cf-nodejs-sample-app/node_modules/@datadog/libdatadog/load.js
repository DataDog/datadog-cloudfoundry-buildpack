'use strict'

// TODO: Extract this file to an external library.

const { existsSync, readdirSync } = require('fs')
const os = require('os')
const path = require('path')

const PLATFORM = os.platform()
const ARCH = process.arch
const LIBC = PLATFORM === 'linux' ? existsSync('/etc/alpine-release') ? 'musl' : 'glibc' : ''
const ABI = process.versions.modules

const inWebpack = typeof __webpack_require__ === 'function'
const runtimeRequire = inWebpack ? __non_webpack_require__ : require

function maybeLoad (name) {
  try {
    return load(name)
  } catch (e) {
    // Not found, skip.
  }
}

function load (name) {
  const filename = find(name)
  const filenameWASM = findWASM(name)

  if (filename) {
    return runtimeRequire(filename)
  } else if (filenameWASM) {
    return runtimeRequire(filenameWASM)
  }
  throw new Error(`Could not find a ${name} binary for ${PLATFORM}${LIBC}-${ARCH} nor a ${name} WASM module.`)
}

function findWASM (name) {
  const root = __dirname
  const prebuilds = path.join(root, 'prebuilds')
  const folders = readdirSync(prebuilds)
  if (folders.find(f => f === name)) {
    return path.join(prebuilds, name, `${name.replaceAll('-', '_')}.js`)
  }
}

function find (name, binary = false) {
  const root = __dirname

  // see https://github.com/rust-lang/cargo/issues/12780
  // Only apply hyphen-to-underscore conversion for .node libraries, not binaries
  const transformedName = binary ? name : name.replaceAll('-', '_')

  const filename = binary ? transformedName : `${transformedName}.node`
  const build = `${root}/build/Release/${filename}`

  if (existsSync(build)) return build

  const folder = findFolder(root)

  if (!folder) return

  const prebuildFolder = path.join(root, 'prebuilds', folder)
  const file = findFile(prebuildFolder, transformedName, binary)

  if (!file) return

  return path.join(prebuildFolder, file)
}

function findFolder (root) {
  try {
    const prebuilds = path.join(root, 'prebuilds')
    const folders = readdirSync(prebuilds)

    return folders.find(f => f === `${PLATFORM}${LIBC}-${ARCH}`)
      || folders.find(f => f === `${PLATFORM}-${ARCH}`)
  } catch (e) {
    return null
  }
}

function findFile (root, name, binary = false) {
  const files = readdirSync(root)

  if (binary) return files.find(f => f === name)

  return files.find(f => f === `${name}-${ABI}.node`)
    || files.find(f => f === `${name}-napi.node`)
    || files.find(f => f === `${name}.node`)
}

module.exports = { find, load, maybeLoad }
