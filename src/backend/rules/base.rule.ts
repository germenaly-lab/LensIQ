export interface RuleContext {
  cameraId: string;
  cameraName: string;
  roiId: string;
  roiName: string;
  peopleInRoi: number;
  timestamp: number; // in seconds
}

export interface AIIncidentEvent {
  id: string;
  eventType: string;
  cameraId: string;
  roiId: string;
  ruleId: string;
  detectedAt: string;
  confidence: number;
  peopleCount: number;
  duration: number;
  metadata: Record<string, any>;
}

export abstract class BaseRule {
  readonly ruleId: string;
  readonly name: string;
  readonly enabled: boolean;

  constructor(ruleId: string, name: string, enabled = true) {
    this.ruleId = ruleId;
    this.name = name;
    this.enabled = enabled;
  }

  abstract evaluate(ctx: RuleContext): AIIncidentEvent | null;
  abstract reset(): void;
}
