/**
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache-2.0 License.
 * This product includes software developed at Datadog (https://www.datadoghq.com/). Copyright 2021 Datadog, Inc.
 **/
type rules = object;

type diagnosticsInfo = {
  addresses?: {
    optional: string[],
    required: string[]
  },
  loaded: string[],
  failed: string[],
  errors: {
    [errorString: string]: string[]
  }
}

type diagnosticsError = {
  error: string
}

type diagnosticsResult = diagnosticsInfo | diagnosticsError

type TruncationMetrics = {
  maxTruncatedString?: number;
  maxTruncatedContainerSize?: number;
  maxTruncatedContainerDepth?: number;
}

type result = {
  timeout: boolean;
  duration?: number;
  events?: object[]; // https://github.com/DataDog/libddwaf/blob/master/schema/events.json
  status?: 'match'; // TODO: remove this if new statuses are never added
  actions?: object[];
  attributes?: object;
  metrics?: TruncationMetrics;
  errorCode?: number;
  keep?: boolean;
}

type payload = {
  persistent?: object,
  ephemeral?: object
}

declare class DDWAFContext {
  readonly disposed: boolean;

  run(payload: payload, timeout: number): result;
  dispose(): void;
}

export class DDWAF {
  static version(): string;

  readonly disposed: boolean;

  readonly configPaths: string[];

  readonly diagnostics: {
    ruleset_version?: string,
    rules?: diagnosticsResult,
    custom_rules?: diagnosticsResult,
    exclusions?: diagnosticsResult,
    rules_override?: diagnosticsResult,
    rules_data?: diagnosticsResult,
    processors?: diagnosticsResult,
    actions?: diagnosticsResult
  };

  readonly knownAddresses: Set<string>;
  readonly knownActions: Set<string>;

  constructor(rules: rules, rulesPath: string, config?: {
    obfuscatorKeyRegex?: string,
    obfuscatorValueRegex?: string
  });

  createOrUpdateConfig(config: rules, path: string): boolean;
  removeConfig(path: string): boolean;

  createContext(): DDWAFContext;
  dispose(): void;
}
