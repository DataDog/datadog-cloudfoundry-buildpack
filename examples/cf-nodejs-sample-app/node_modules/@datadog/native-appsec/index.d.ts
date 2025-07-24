/**
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache-2.0 License.
 * This product includes software developed at Datadog (https://www.datadoghq.com/). Copyright 2021 Datadog, Inc.
 **/
type rules = object;

type result = {
  timeout: boolean;
  totalRuntime?: number;
  data?: string;
  status?: 'match'; // TODO: remove this if new statuses are never added
  actions?: string[];
};

declare class DDWAFContext {
  readonly disposed: boolean;

  run(inputs: object, timeout: number): result;
  dispose(): void;
}

export class DDWAF {
  static version(): string;

  readonly disposed: boolean;

  readonly rulesInfo: {
    version?: string,
    loaded: number,
    failed: number,
    errors: {
      [errorString: string]: string[]
    }
  };

  constructor(rules: rules, config?: {
    obfuscatorKeyRegex?: string,
    obfuscatorValueRegex?: string
  });

  updateRuleData(ruleData: object[]): void;

  createContext(): DDWAFContext;
  dispose(): void;
}
