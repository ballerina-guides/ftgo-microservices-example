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

import ballerina/test;
import ballerina/http;

type ConsumerChargedRecord record {|
    *Bill;
    *http:Links;
|};

type BillViewRecord record {|
    *Bill;
    *http:Links;
|};

http:Client accountingClient = check new("http://localhost:8083/");

@test:Config {
    groups: ["charge"]
}
function chargeTest() returns error? {
    http:Request chargeRequest = new;
    ChargeRequest requestPayload = {
        consumerId: 1,
        orderId: 1,
        orderAmount: 12.34
    };
    chargeRequest.setJsonPayload(requestPayload);
    http:Response response = check accountingClient->post("charge", chargeRequest);
    test:assertEquals(response.statusCode, 200);

    ConsumerChargedRecord returnData = check (check response.getJsonPayload()).cloneWithType();
    test:assertEquals(returnData.'order.id, requestPayload.orderId);
    test:assertEquals(returnData.'order.orderItems.length(), 2);
    test:assertEquals(returnData.consumer.id, requestPayload.consumerId);
    test:assertEquals(returnData.orderAmount, requestPayload.orderAmount);
    test:assertEquals(returnData._links.length(), 1);
}

@test:Config {
    groups: ["charge"]
}
function chargeTestNegative1() returns error? {
    http:Request chargeRequest = new;
    ChargeRequest requestPayload = {
        consumerId: 2,
        orderId: 1,
        orderAmount: 12.34
    };
    chargeRequest.setJsonPayload(requestPayload);
    http:Response response = check accountingClient->post("charge", chargeRequest);
    test:assertEquals(response.statusCode, 500);
}

@test:Config {
    groups: ["charge"]
}
function chargeTestNegative2() returns error? {
    http:Request chargeRequest = new;
    ChargeRequest requestPayload = {
        consumerId: 1,
        orderId: 2,
        orderAmount: 12.34
    };
    chargeRequest.setJsonPayload(requestPayload);
    http:Response response = check accountingClient->post("charge", chargeRequest);
    test:assertEquals(response.statusCode, 500);
}

@test:Config {
    groups: ["bill"]
}
function getBillTest() returns error? {
    http:Request chargeRequest = new;
    ChargeRequest requestPayload = {
        consumerId: 1,
        orderId: 1,
        orderAmount: 12.34
    };
    chargeRequest.setJsonPayload(requestPayload);
    http:Response response = check accountingClient->post("charge", chargeRequest);
    ConsumerChargedRecord returnData = check (check response.getJsonPayload()).cloneWithType();
    int billId = returnData.id;

    response = check accountingClient->get("bill/" + billId.toString());
    test:assertEquals(response.statusCode, 200);

    BillViewRecord returnData2 = check (check response.getJsonPayload()).cloneWithType();
    test:assertEquals(returnData2.id, billId);
    test:assertEquals(returnData2.consumer.id, requestPayload.consumerId);
    test:assertEquals(returnData2.'order.id, requestPayload.orderId);
    test:assertEquals(returnData2.orderAmount, requestPayload.orderAmount);
    test:assertEquals(returnData2._links.length(), 1);
}

@test:Config {
    groups: ["bill"]
}
function getBillTestNegative() returns error? {
    http:Request chargeRequest = new;
    ChargeRequest requestPayload = {
        consumerId: 1,
        orderId: 1,
        orderAmount: 12.34
    };
    chargeRequest.setJsonPayload(requestPayload);
    http:Response response = check accountingClient->post("charge", chargeRequest);
    ConsumerChargedRecord returnData = check (check response.getJsonPayload()).cloneWithType();
    int billIdNext = returnData.id + 1;

    response = check accountingClient->get("bill/" + billIdNext.toString());
    test:assertEquals(response.statusCode, 404);
}
