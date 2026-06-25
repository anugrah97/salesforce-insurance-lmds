import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';

import LEAD_SCORE_FIELD       from '@salesforce/schema/Lead.Lead_Score__c';
import PROPENSITY_FIELD       from '@salesforce/schema/Lead.Propensity_Score__c';
import ENGAGEMENT_FIELD       from '@salesforce/schema/Lead.Engagement_Score__c';
import SCORE_TAG_FIELD        from '@salesforce/schema/Lead.Score_Tag__c';
import ACTIVITY_COUNT_FIELD   from '@salesforce/schema/Lead.Activity_Count__c';
import LAST_UPDATED_FIELD     from '@salesforce/schema/Lead.Last_Score_Updated__c';

const FIELDS = [
    LEAD_SCORE_FIELD,
    PROPENSITY_FIELD,
    ENGAGEMENT_FIELD,
    SCORE_TAG_FIELD,
    ACTIVITY_COUNT_FIELD,
    LAST_UPDATED_FIELD
];

export default class AiInsightsPanel extends LightningElement {
    @api recordId;

    isLoading = true;
    _record;

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredRecord({ error, data }) {
        if (data) {
            this._record = data;
            this.isLoading = false;
        } else if (error) {
            this.isLoading = false;
            console.error('AI Insights: Error loading record', error);
        }
    }

    // ─── Score Getters ──────────────────────────────────────────────────────

    get leadScore() {
        return getFieldValue(this._record, LEAD_SCORE_FIELD) ?? 0;
    }

    get propensityScore() {
        return getFieldValue(this._record, PROPENSITY_FIELD) ?? 0;
    }

    get engagementScore() {
        return getFieldValue(this._record, ENGAGEMENT_FIELD) ?? 0;
    }

    get scoreTag() {
        return getFieldValue(this._record, SCORE_TAG_FIELD) ?? 'Normal';
    }

    get activityCount() {
        return getFieldValue(this._record, ACTIVITY_COUNT_FIELD) ?? 0;
    }

    get lastUpdated() {
        return getFieldValue(this._record, LAST_UPDATED_FIELD);
    }

    get lastUpdatedFormatted() {
        if (!this.lastUpdated) return '';
        return new Date(this.lastUpdated).toLocaleString('en-IN', {
            day: '2-digit', month: 'short', year: 'numeric',
            hour: '2-digit', minute: '2-digit'
        });
    }

    // ─── Tag Getters ────────────────────────────────────────────────────────

    get isHot()    { return this.scoreTag === 'Hot'; }
    get isAtRisk() { return this.scoreTag === 'At Risk'; }

    // ─── CSS Classes ────────────────────────────────────────────────────────

    get leadScoreClass()      { return this._scoreClass(this.leadScore); }
    get propensityScoreClass(){ return this._scoreClass(this.propensityScore); }
    get engagementScoreClass(){ return this._scoreClass(this.engagementScore); }

    get leadScoreBarClass()      { return this._barClass(this.leadScore); }
    get propensityBarClass()     { return this._barClass(this.propensityScore); }
    get engagementBarClass()     { return this._barClass(this.engagementScore); }

    get leadScoreBarStyle()      { return `width: ${this.leadScore}%`; }
    get propensityBarStyle()     { return `width: ${this.propensityScore}%`; }
    get engagementBarStyle()     { return `width: ${this.engagementScore}%`; }

    _scoreClass(score) {
        const base = 'score-number ';
        if (score >= 70) return base + 'score-green';
        if (score >= 40) return base + 'score-amber';
        return base + 'score-red';
    }

    _barClass(score) {
        const base = 'score-bar-fill ';
        if (score >= 70) return base + 'bar-green';
        if (score >= 40) return base + 'bar-amber';
        return base + 'bar-red';
    }
}
