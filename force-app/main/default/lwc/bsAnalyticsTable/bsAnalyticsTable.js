import { LightningElement, api, track, wire } from "lwc";
import getBSAnalytics from "@salesforce/apex/DocsumoBSAnalytics.getBSAnalytics";
import { getRecord } from "lightning/uiRecordApi";
import DOC_ID_FIELD from "@salesforce/schema/DS_us_bank_statement__c.doc_id__c";

export default class BsAnalyticsTable extends LightningElement {
  @api recordId;
  @track docId;
  @track basicMetricsData = [];
  @track basicMetricsColumns = [
    { label: "Average Amount", fieldName: "average_amount", type: "currency" },
    {
      label: "Average Daily balance",
      fieldName: "average_daily_balance",
      type: "currency"
    },
    {
      label: "Average Weekday balance",
      fieldName: "average_weekday_balance",
      type: "currency"
    },
    { label: "Max Credit", fieldName: "max_credit", type: "currency" },
    { label: "Max Debit", fieldName: "max_debit", type: "currency" }
  ];

  @track monthlyMetricsData = [];
  @track monthlyColumns = [
    { label: "Month", fieldName: "month", type: "text" },
    {
      label: "Average Transaction Amount",
      fieldName: "average_transaction_amount",
      type: "currency"
    },
    { label: "Total Credit", fieldName: "total_credit", type: "currency" },
    { label: "Total Debit", fieldName: "total_debit", type: "currency" },
    { label: "Total Amount", fieldName: "total_amount", type: "currency" }
  ];

  @track quarterlyMetricsData = [];
  @track quarterlyColumns = [
    { label: "Quarter", fieldName: "quarter", type: "text" },
    {
      label: "Average Transaction Amount",
      fieldName: "average_transaction_amount",
      type: "currency"
    },
    { label: "Total Credit", fieldName: "total_credit", type: "currency" },
    { label: "Total Debit", fieldName: "total_debit", type: "currency" },
    { label: "Total Amount", fieldName: "total_amount", type: "currency" }
  ];

  @track isLoading = true;
  @track errorMsg;

  @wire(getRecord, { recordId: "$recordId", fields: [DOC_ID_FIELD] })
  wiredRecord({ error, data }) {
    if (data) {
      this.docId = data.fields.doc_id__c.value;
      this.errorMsg = undefined;
      this.isLoading = false;
      this.fetchAnalytics(this.docId);
    } else if (error) {
      this.errorMsg = "Failed to retrieve document ID.";
      this.docId = undefined;
      this.isLoading = false;
    }
  }

  handleRetry = () => {
    this.errorMsg = undefined;
    this.isLoading = true;
    this.fetchAnalytics(this.docId);
  }

  fetchAnalytics(docId) {
    this.isLoading = true;

    getBSAnalytics({ docId: docId })
      .then((result) => {
        let jsonResult = JSON.parse(result);

        if (jsonResult.error) {
          this.errorMsg = jsonResult.message;
          return;
        }

        this.basicMetricsData = [jsonResult.basic_metrics];

        //prepare quarterly metrics
        let metricsData = [];
        for (let q in jsonResult.quarterly_analytics) {
          metricsData.push({
            quarter: q.toUpperCase(),
            ...jsonResult.quarterly_analytics[q]
          });
        }
        this.quarterlyMetricsData = metricsData;

        //prepare monthly metrics
        let mMetricsData = [];
        for (let q in jsonResult.monthly_analytics) {
          let data = jsonResult.monthly_analytics[q];
          mMetricsData.push({
            month: q,
            average_transaction_amount: data.average_transaction_amount || 0,
            total_credit: data.credit.total_amount || 0,
            total_debit: data.debit.total_amount || 0,
            total_amount: data.total_amount || 0
          });

          this.monthlyMetricsData = mMetricsData;
        }

        this.errorMsg = undefined;
      })
      .catch((error) => {
        console.log("error while fetching analytics");
        console.log(error);
        this.errorMsg = "Failed to load analytics.";
        this.basicMetricsData = undefined;
      })
      .finally(() => {
        this.isLoading = false;
      });
  }
}