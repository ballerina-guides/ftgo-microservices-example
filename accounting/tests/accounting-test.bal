import ballerina/test;
import ballerina/log;
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

    log:printInfo((check response.getJsonPayload()).toJsonString());
    ConsumerChargedRecord returnData = check (check response.getJsonPayload()).cloneWithType();
    test:assertEquals(returnData.'order.id, requestPayload.orderId);
    test:assertEquals(returnData.'order.orderItems.length(), 2);
    test:assertEquals(returnData.consumer.id, requestPayload.consumerId);
    test:assertEquals(returnData.orderAmount, requestPayload.orderAmount);
    test:assertEquals(returnData.links.length(), 1);
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
    log:printInfo(returnData.toJsonString());

    response = check accountingClient->get("bill/" + billId.toString());
    test:assertEquals(response.statusCode, 200);

    BillViewRecord returnData2 = check (check response.getJsonPayload()).cloneWithType();
    test:assertEquals(returnData2.id, billId);
    test:assertEquals(returnData2.consumer.id, requestPayload.consumerId);
    test:assertEquals(returnData2.'order.id, requestPayload.orderId);
    test:assertEquals(returnData2.orderAmount, requestPayload.orderAmount);
    test:assertEquals(returnData2.links.length(), 1);
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
    log:printInfo(returnData.toJsonString());

    response = check accountingClient->get("bill/" + billIdNext.toString());
    test:assertEquals(response.statusCode, 404);
}
