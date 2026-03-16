import dcModule from './dc-polyfill.js';

export default dcModule;

// Always export all required functions, whether they exist or we need to create them
export const Channel = dcModule.Channel;
export const channel = dcModule.channel;
export const hasSubscribers = dcModule.hasSubscribers;
export const tracingChannel = dcModule.tracingChannel;
export const subscribe = dcModule.subscribe;
export const unsubscribe = dcModule.unsubscribe;
