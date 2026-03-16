# libdatadog-nodejs

Node.js bindings for [libdatadog](https://github.com/DataDog/libdatadog).

## Installing

This project is currently meant to be used only by [dd-trace-js](https://github.com/DataDog/dd-trace-js)
and installing it directly is not supported at the moment.

## Building

* `yarn build`: Build the default workspaces in debug mode.
* `yarn build-release`: Build the default workspaces in release mode.
* `yarn build-all`: Build all workspaces in debug mode. This is useful when working on a workspace that is not a default member yet.
