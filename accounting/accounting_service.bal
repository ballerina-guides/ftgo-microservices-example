// Copyright (c) 2022 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/http;
import ballerina/log;
import ballerina/sql;

# Request body to be used when charging a consumer
type ChargeRequest record {|
    # The ID of the consumer to be charged  
    int consumerId;
    # The ID of the order associated with the charge  
    int orderId;
    # The amount to be charged
    decimal orderAmount;
|};

# Response when a consumer is successfully charged
type ConsumerCharged record {|
    *http:Ok;
    # The details of the generated bill along with the relevant HTTP links
    record {|
        *Bill;
        *http:Links;
    |} body;
|};

# Response when a bill is successfully retrieved
type BillView record {|
    *http:Ok;
    # The details of the generated bill along with the relevant HTTP links
    record {|
        *Bill;
        *http:Links;
    |} body;
|};

# Response when a requested bill cannot be found
type BillNotFound record {|
    *http:NotFound;
    # Error message
    readonly record {} body = { 
        "message": "Bill cannot be found." 
    };
|};

# Represents an unexpected error
type InternalError record {|
   *http:InternalServerError;
    # Error payload
    record {| 
        string message;
    |} body;
|}; 

# Listener for the Accounting service
service on new http:Listener(8083) {

    # Resource function to charge a consumer for an order placed
    #
    # + request - Details of the charge
    # + return - `ConsumerCharged` if the charge was successfully initiated.
    #            `InternalError` if an unexpected error occurs
    isolated resource function post charge(@http:Payload ChargeRequest request) returns ConsumerCharged|InternalError {
        do {
            Bill generatedBill = check createBill(request.consumerId, request.orderId, request.orderAmount);
            check chargeConsumer(request.consumerId, request.orderAmount);

            return <ConsumerCharged>{ 
                body:{
                    ...generatedBill,
                    links: getLinks(generatedBill.id)
                } 
            };
        } on fail error e {
            log:printError("Error in processing charge request", e, e.stackTrace());
            return <InternalError>{ body: { message: e.message() }};
        }
    }

    # Resource function to retrieve a bill
    #
    # + id - The ID of the bill to be retrieved
    # + return - `BillView` if the details are successfully fetched.
    #            `BillNotFound` if a bill with the provided ID was not found.
    #            `InternalError` if an unexpected error occurs
    isolated resource function get bill/[int id]() returns BillView|BillNotFound|InternalError {
        do {
            Bill bill = check getBill(id);
            return <BillView>{ 
                body:{
                    ...bill,
                    links: getLinks(id)
                } 
            };
        } on fail error e {
            log:printError("Error in retrieving bill.", e, e.stackTrace());
            if e is sql:NoRowsError {
                return <BillNotFound>{};
            }
            return <InternalError>{ body: { message: e.message() }};
        }
    }

}

# Obtain the HTTP links related to a given bill
#
# + billId - The ID of the bill
# + return - An array of links
isolated function getLinks(int billId) returns http:Link[] {
    return [
        {
            rel: "view",
            href: "/bill/" + billId.toString(),
            methods: [http:GET]
        }
    ];
}

