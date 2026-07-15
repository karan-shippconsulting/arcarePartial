@isTest
public class TruelinkTransactionResponseWrapperTest {
	@isTest
    static void testParse() {
		String json = '{'+
		'  "data": ['+
		'    {'+
		'      "id": "string",'+
		'      "type": "disbursement",'+
		'      "attributes": {'+
		'        "amount": {'+
		'          "amount": 0,'+
		'          "currency": "USD"'+
		'        },'+
		'        "clearedDate": "2024-12-25",'+
		'        "checkMemoLine": "string",'+
		'        "deliveryDate": "2024-12-25",'+
		'        "payeeAddress": {'+
		'          "street1": "string",'+
		'          "street2": "string",'+
		'          "city": "string",'+
		'          "state": "string",'+
		'          "zip": "string"'+
		'        },'+
		'        "payeeBankAccount": {'+
		'          "accountNumber": "string",'+
		'          "routingNumber": "string"'+
		'        },'+
		'        "payeeMemo": "string",'+
		'        "payeeDisposition": "string",'+
		'        "payeeName": "string",'+
		'        "payeeDescription": "string",'+
		'        "payeeSpecialInstructions": "string",'+
		'        "payeeSwiftCode": "string",'+
		'        "paymentMethod": "string",'+
		'        "postageType": "string",'+
		'        "status": "string",'+
		'        "requestorDescription": "string",'+
		'        "requestedBySignature": "string",'+
		'        "postageCode": 0,'+
		'        "checkNum": 0,'+
		'        "updatedAt": "2024-12-25T08:35:27.825Z"'+
		'      },'+
		'      "meta": {'+
		'        "displayCategory": "string",'+
		'        "displayPaymentMethod": "string"'+
		'      },'+
		'      "relationships": {'+
		'        "attachments": {'+
		'          "data": ['+
		'            {'+
		'              "id": "string",'+
		'              "type": "attachment"'+
		'            }'+
		'          ]'+
		'        },'+
		'        "decisions": {'+
		'          "data": ['+
		'            {'+
		'              "id": "string",'+
		'              "type": "disbursement_decision"'+
		'            }'+
		'          ]'+
		'        },'+
		'        "categoryAmounts": {'+
		'          "data": ['+
		'            {'+
		'              "id": "string",'+
		'              "type": "disbursement_category_amount"'+
		'            }'+
		'          ]'+
		'        },'+
		'        "smartpayablesInsert": {'+
		'          "data": {'+
		'            "id": "string",'+
		'            "type": "attachment"'+
		'          }'+
		'        },'+
		'        "sourceBankAccount": {'+
		'          "data": {'+
		'            "id": "string",'+
		'            "type": "bank_account"'+
		'          }'+
		'        }'+
		'      }'+
		'    }'+
		'  ],'+
		'  "included": ['+
		'    {'+
		'      "id": "string",'+
		'      "type": "user",'+
		'      "attributes": {'+
		'        "firstName": "string",'+
		'        "lastName": "string",'+
		'        "email": "string",'+
		'        "siteAdmin": true'+
		'      },'+
		'      "meta": {}'+
		'    },'+
		'    {'+
		'      "id": "string",'+
		'      "type": "disbursement_category_amount",'+
		'      "attributes": {'+
		'        "firstName": "string",'+
		'        "lastName": "string",'+
		'        "email": "string",'+
		'        "siteAdmin": true,'+
		'        "amount": {'+
		'          "amount": 0,'+
		'          "currency": "USD"'+
		'        },'+
		'        "category": "string",'+
		'        "notes": "string"'+
		'      },'+
		'      "meta": {},'+
		'      "relationships": {'+
		'        "attachments": {'+
		'          "data": ['+
		'            {'+
		'              "id": "string",'+
		'              "type": "attachment"'+
		'            }'+
		'          ]'+
		'        }'+
		'      }'+
		'    }'+
		'  ],'+
		'  "meta": {'+
		'    "page": {},'+
		'    "displayCategory": "string",'+
		'    "displayPaymentMethod": "string"'+
		'  }'+
		'}';
        
		TruelinkTransactionResponseWrapper obj = new TruelinkTransactionResponseWrapper();
        obj.parse(json);
		System.assert(obj != null);
	}
}