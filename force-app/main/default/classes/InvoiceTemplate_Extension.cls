/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 09-09-2024
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public class InvoiceTemplate_Extension{
    private final Opportunity opt;
    public Map<String,Decimal> agging{ get; set; } 
    public Decimal aggigingTotal { get; set; } 

    public Decimal directExpenseSubtotalQuantity { get; set; } 
    public Decimal directExpenseSubtotalPrice { get; set; } 
    
    public Decimal hourlyServiceSubtotalQuantity { get; set; } 
    public Decimal hourlyServiceSubtotalPrice { get; set; } 

    public Decimal totalFinalPrice { get; set; } 
    public Decimal feesSubtotalPrice{get;set;}
    public Decimal feesSubtotalQuantity{get;set;}

    /** VF component Properties*/
    
    public Opportunity controllerValue;

    public Map<String,Decimal> aggingForComponent{ get; set; } 
    public Decimal aggigingTotalForComponent { get; set; } 

    public Decimal directExpenseSubtotalQuantityForComponent { get; set; } 
    public Decimal directExpenseSubtotalPriceForComponent { get; set; } 
    
    public Decimal hourlyServiceSubtotalQuantityForComponent { get; set; } 
    public Decimal hourlyServiceSubtotalPriceForComponent { get; set; } 

    public Decimal totalFinalPriceForComponent { get; set; } 
    
    public Decimal feesSubtotalPriceForComponent{get;set;}
    public Decimal feesSubtotalQuantityForComponent{get;set;}
    /** VF Component Properties */

    public InvoiceTemplate_Extension(){
        
    }
    public InvoiceTemplate_Extension(ApexPages.StandardController stdController) {
        this.feesSubtotalPrice = 0;
        this.feesSubtotalQuantity = 0;

        this.opt = (Opportunity)stdController.getRecord();
        this.agging=new Map<String,Decimal>();
        this.aggigingTotal = 0 ;
        
        this.directExpenseSubtotalQuantity = 0 ;
        this.directExpenseSubtotalPrice = 0;

        this.hourlyServiceSubtotalQuantity = 0;
        this.hourlyServiceSubtotalPrice = 0;
        this.totalFinalPrice = 0;
            
        agging.put('1-30 Days',0.00);
        agging.put('31-60 Days',0.00);
        agging.put('61-90 Days',0.00);
        agging.put('90+ Days',0.00);
        for(Opportunity opp : [
            SELECT ID,Days_Aging_Range__c,Amount
            FROM Opportunity
            WHERE STAGENAME='Posted' 
            AND Service_Enrollment__c=:this.opt.Service_Enrollment__c
            AND Payment_Status__c =:'Open' 
            AND Days_Aging_Range__c!=: null
            ORDER BY Days_Aging_Range__c ASC
        ]){
            aggigingTotal = aggigingTotal+opp.Amount.setScale(2);
            if(agging.containsKey(opp.Days_Aging_Range__c)){
                Decimal count = agging.get(opp.Days_Aging_Range__c)+opp.Amount;
                agging.put(opp.Days_Aging_Range__c,count.setScale(2));
            } else {
                agging.put(opp.Days_Aging_Range__c,opp.Amount.setScale(2));
            }

        }

        AggregateResult[] groupedResults =  [SELECT PricebookEntry.Product2.Charge_Type__c chargetype ,
        sum(Quantity) Quantity,
        sum(TotalPrice) TotalPrice  
        FROM OpportunityLineItem  
        WHERE OpportunityId  =:this.opt.Id
        GROUP BY PricebookEntry.Product2.Charge_Type__c ];
        for (AggregateResult ar : groupedResults)  {
            String chargeType = (String)ar.get('chargetype');
            if(chargeType == 'HOURLY SERVICE' ){
                this.hourlyServiceSubtotalQuantity = (Decimal)ar.get('Quantity');
                this.hourlyServiceSubtotalPrice = (Decimal)ar.get('TotalPrice');

            } else if(chargeType == 'DIRECT EXPENSE') {
                this.directExpenseSubtotalQuantity =  (Decimal)ar.get('Quantity');
                this.directExpenseSubtotalPrice =  (Decimal)ar.get('TotalPrice');
                
            } else if(chargeType == 'FEES') {
                this.feesSubtotalQuantity =  (Decimal)ar.get('Quantity');
                this.feesSubtotalPrice =  (Decimal)ar.get('TotalPrice');
            }
        }
        this.totalFinalPrice = this.hourlyServiceSubtotalPrice + this.directExpenseSubtotalPrice + this.feesSubtotalPrice;
    }

    

    public void setControllerValue (Opportunity s) {
        controllerValue = s;
        this.setAllVariableValues(s);
    }
        
    public Opportunity getControllerValue() {
        return controllerValue;
    } 


    public void setAllVariableValues(Opportunity opt) {
        this.feesSubtotalPriceForComponent = 0;
        this.feesSubtotalQuantityForComponent = 0;
        
        
        this.aggingForComponent=new Map<String,Decimal>();
        this.aggigingTotalForComponent = 0 ;
        
        this.directExpenseSubtotalQuantityForComponent = 0 ;
        this.directExpenseSubtotalPriceForComponent = 0;

        this.hourlyServiceSubtotalQuantityForComponent = 0;
        this.hourlyServiceSubtotalPriceForComponent = 0;
        this.totalFinalPriceForComponent = 0;
        
		aggingForComponent.put('1-30 Days',0.00);
        aggingForComponent.put('31-60 Days',0.00);
        aggingForComponent.put('61-90 Days',0.00);
        aggingForComponent.put('90+ Days',0.00);
        for(Opportunity opp : [
            SELECT ID,Days_Aging_Range__c,Amount
            FROM Opportunity
            WHERE STAGENAME='Posted' 
            AND Service_Enrollment__c=:opt.Service_Enrollment__c
            AND Payment_Status__c =:'Open' 
            AND Days_Aging_Range__c!=: null
            ORDER BY Days_Aging_Range__c ASC
        ]){
            this.aggigingTotalForComponent = this.aggigingTotalForComponent+opp.Amount.setScale(2);
            if(this.aggingForComponent.containsKey(opp.Days_Aging_Range__c)){
                Decimal count = this.aggingForComponent.get(opp.Days_Aging_Range__c)+opp.Amount;
                this.aggingForComponent.put(opp.Days_Aging_Range__c,count.setScale(2));
            } else {
                this.aggingForComponent.put(opp.Days_Aging_Range__c,opp.Amount.setScale(2));
            }
            
        }

        AggregateResult[] groupedResults =  [SELECT PricebookEntry.Product2.Charge_Type__c chargetype ,
        sum(Quantity) Quantity,
        sum(TotalPrice) TotalPrice  
        FROM OpportunityLineItem  
        WHERE OpportunityId  =:opt.Id
        GROUP BY PricebookEntry.Product2.Charge_Type__c ];
        for (AggregateResult ar : groupedResults)  {
            String chargeType = (String)ar.get('chargetype');
            if(chargeType == 'HOURLY SERVICE' ){
                this.hourlyServiceSubtotalQuantityForComponent = (Decimal)ar.get('Quantity');
                this.hourlyServiceSubtotalPriceForComponent = (Decimal)ar.get('TotalPrice');

            } else if(chargeType == 'DIRECT EXPENSE') {
                this.directExpenseSubtotalQuantityForComponent =  (Decimal)ar.get('Quantity');
                this.directExpenseSubtotalPriceForComponent =  (Decimal)ar.get('TotalPrice');
            } else if(chargeType == 'FEES') {
                this.feesSubtotalPriceForComponent =  (Decimal)ar.get('Quantity');
                this.feesSubtotalQuantityForComponent =  (Decimal)ar.get('TotalPrice');
            }
        }
        this.totalFinalPriceForComponent = this.hourlyServiceSubtotalPriceForComponent + this.directExpenseSubtotalPriceForComponent;
      
    }

}