import { BaseRule, RuleContext, AIIncidentEvent } from './base.rule';

export interface CashierEmptyRuleOptions {
  ruleId?: string;
  name?: string;
  minimumPeople?: number;
  durationSeconds?: number;
  enabled?: boolean;
}

export class CashierEmptyRule extends BaseRule {
  readonly minimumPeople: number;
  readonly durationSeconds: number;

  private emptyStartTime: number | null = null;
  private hasTriggered = false;
  private currentDuration = 0;

  constructor(options: CashierEmptyRuleOptions = {}) {
    super(
      options.ruleId ?? 'rule-cashier-empty-01',
      options.name ?? 'Cashier Area Empty Rule',
      options.enabled ?? true
    );
    this.minimumPeople = options.minimumPeople ?? 0;
    this.durationSeconds = options.durationSeconds ?? 180.0;
  }

  getCurrentDuration(): number {
    return this.currentDuration;
  }

  getHasTriggered(): boolean {
    return this.hasTriggered;
  }

  evaluate(ctx: RuleContext): AIIncidentEvent | null {
    if (!this.enabled) return null;

    const currentTime = ctx.timestamp;
    const peopleCount = ctx.peopleInRoi;

    if (peopleCount <= this.minimumPeople) {
      if (this.emptyStartTime === null) {
        this.emptyStartTime = currentTime;
        this.currentDuration = 0;
      } else {
        this.currentDuration = currentTime - this.emptyStartTime;
      }

      if (this.currentDuration >= this.durationSeconds) {
        if (!this.hasTriggered) {
          this.hasTriggered = true;
          return {
            id: `evt_${ctx.cameraId}_${Math.floor(currentTime)}`,
            eventType: 'CASHIER_EMPTY',
            cameraId: ctx.cameraId,
            roiId: ctx.roiId,
            ruleId: this.ruleId,
            detectedAt: new Date().toISOString(),
            confidence: 1.0,
            peopleCount: 0,
            duration: Math.round(this.currentDuration),
            metadata: {
              ruleName: this.name,
              roiName: ctx.roiName,
              thresholdSeconds: this.durationSeconds,
              emptySince: this.emptyStartTime,
            },
          };
        } else {
          // Already triggered for this continuous empty episode. Suppress duplicate alerts!
          return null;
        }
      }
    } else {
      // Person entered ROI -> reset timer completely!
      this.emptyStartTime = null;
      this.hasTriggered = false;
      this.currentDuration = 0;
    }

    return null;
  }

  reset(): void {
    this.emptyStartTime = null;
    this.hasTriggered = false;
    this.currentDuration = 0;
  }
}
