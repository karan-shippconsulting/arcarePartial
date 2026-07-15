@isTest
public class TrueLinkResponseWrapperTest {
	static testMethod void testParse() {
		String json=		'{'+
		'    "data": {'+
		'        "type": "trust_beneficiary",'+
		'        "id": "teri-shipp-x4961706",'+
		'        "attributes": {'+
		'            "prefix": "Mr",'+
		'            "firstName": "Teri",'+
		'            "middleName": null,'+
		'            "lastName": "Shipp",'+
		'            "suffix": "Jr",'+
		'            "mobile": null,'+
		'            "email": "teri@shippconsulting.com",'+
		'            "externalId": "123",'+
		'            "ein": "",'+
		'            "taxIdNumberType": "ein",'+
		'            "age": 0,'+
		'            "dob": "2024-04-24",'+
		'            "gender": "Female",'+
		'            "trustBeneficiaryInternalId": "981009",'+
		'            "maritalStatus": null,'+
		'            "livingSituation": null'+
		'        },'+
		'        "relationships": {'+
		'            "accounts": {'+
		'                "data": []'+
		'            },'+
		'            "address": {'+
		'                "data": {'+
		'                    "type": "address",'+
		'                    "id": "2934a4dd13f0252b0942897603e7b6e1"'+
		'                }'+
		'            },'+
		'            "disabilityDesignation": null,'+
		'            "governmentBenefitsTrustBeneficiary": {'+
		'                "data": []'+
		'            },'+
		'            "organization": {'+
		'                "data": {'+
		'                    "type": "organization",'+
		'                    "id": "cfpd-api-sandbox-x7783714"'+
		'                }'+
		'            },'+
		'            "trust": {'+
		'                "data": {'+
		'                    "type": "trust",'+
		'                    "id": "cfpd-1p-api-sandbow-pool-x7240131"'+
		'                }'+
		'            },'+
		'            "activePortfolio": {'+
		'                "data": {'+
		'                    "type": "portfolio",'+
		'                    "id": "cash-70940063-3556-4fd3-a402-642e68f9f7be"'+
		'                }'+
		'            }'+
		'        }'+
		'    }'+
		'}';
    	TrueLinkResponseWrapper.parse(json);
	}
}