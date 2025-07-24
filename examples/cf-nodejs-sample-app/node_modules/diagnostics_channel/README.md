# diagnostics_channel-polyfill
Exposes a polyfill for the Node.js module `diagnostics_channel`.

As of now, the Node.js module `diagnostics_channel` is only available in Node `^14.17.0 || >=15.1.0`.
This aim to allow using the same API on older versions of Node.

### Install
```sh
npm i diagnostics_channel
```

### Usage
Refer to the official documentation: https://nodejs.org/api/diagnostics_channel.html

### Notes
- This module and the one included in Node core do NOT share the same channels, they live independently.
- Since `WeakReference` is not available, channels will NOT be garbage collected when no reference is held in user-land. An additional function is provided to do manual cleanup if needed: `dc.deleteChannel()`. **This should not be needed in a typical scenario. Only use this method if you know why you are doing it.**
```js
const dc = require('diagnostics_channel');

const a = dc.channel('test');
const b = dc.channel('test');

// channel is memoized
console.log(a === b); // true

dc.deleteChannel('test');

const c = dc.channel('test');

// memoized channel was deleted and a new instance was memoized
console.log(a === c); // false

```
- Since `ERR_INVALID_ARG_TYPE` is not available, a simplfied copy of this error is included.
- Since `triggerUncaughtException()` is not available, if an exception is thrown in a subscriber, the polyfill will instead simply re-throw the error inside a `process.nextTick()`, which has a similar behavior except when the process crashes because of that exception: the crash message will point to this polyfill instead of where the error was created (ie: in the subscriber).
