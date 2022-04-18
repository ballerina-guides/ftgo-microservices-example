import ballerina/test;
import ballerina/log;
import ballerina/http;

type DeliveryScheduledRecord record {|
    *Delivery;
    *http:Links;
|};

type DeliveryViewRecord record {|
    *Delivery;
    *http:Links;
|};

http:Client deliveryClient = check new("http://localhost:8084/delivery/");

@test:Config {
    groups: ["delivery"]
}
function scheduleDeliveryTest() returns error? {
    http:Request scheduleDeliveryRequest = new;
    ScheduleDeliveryRequest requestPayload = {
        orderId: 1,
        pickUpAddress: "test pickup address",
        deliveryAddress: "test delivery address"
    };
    scheduleDeliveryRequest.setJsonPayload(requestPayload.toJson());
    http:Response response = check deliveryClient->post("schedule", scheduleDeliveryRequest);
    test:assertEquals(response.statusCode, 201);

    log:printInfo((check response.getJsonPayload()).toJsonString());
    DeliveryScheduledRecord returnData = check (check response.getJsonPayload()).cloneWithType();
    test:assertEquals(returnData.'order.id, requestPayload.orderId);
    test:assertEquals(returnData.pickUpAddress, requestPayload.pickUpAddress);
    test:assertEquals(returnData.deliveryAddress, requestPayload.deliveryAddress);
}

@test:Config {
    groups: ["delivery"]
}
function scheduleDeliveryNegativeTest() returns error? {
    http:Request scheduleDeliveryRequest = new;
    ScheduleDeliveryRequest requestPayload = {
        orderId: 2,
        pickUpAddress: "test pickup address",
        deliveryAddress: "test delivery address"
    };
    scheduleDeliveryRequest.setJsonPayload(requestPayload.toJson());
    http:Response response = check deliveryClient->post("schedule", scheduleDeliveryRequest);
    test:assertEquals(response.statusCode, 500);
}

@test:Config {
    groups: ["delivery"]
}
function getDeliveryTest() returns error? {
    http:Request scheduleDeliveryRequest = new;
    ScheduleDeliveryRequest requestPayload = {
        orderId: 1,
        pickUpAddress: "test pickup address",
        deliveryAddress: "test delivery address"
    };
    scheduleDeliveryRequest.setJsonPayload(requestPayload.toJson());
    http:Response response = check deliveryClient->post("schedule", scheduleDeliveryRequest);
    test:assertEquals(response.statusCode, 201);
    DeliveryScheduledRecord returnData = check (check response.getJsonPayload()).cloneWithType();

    response = check deliveryClient->get(returnData.id.toString());
    test:assertEquals(response.statusCode, 200);
    returnData = check (check response.getJsonPayload()).cloneWithType();
    test:assertEquals(returnData.'order.id, requestPayload.orderId);
    test:assertEquals(returnData.pickUpAddress, requestPayload.pickUpAddress);
    test:assertEquals(returnData.deliveryAddress, requestPayload.deliveryAddress);
}

@test:Config {
    groups: ["delivery"]
}
function getDeliveryNegativeTest() returns error? {
    http:Request scheduleDeliveryRequest = new;
    ScheduleDeliveryRequest requestPayload = {
        orderId: 1,
        pickUpAddress: "test pickup address",
        deliveryAddress: "test delivery address"
    };
    scheduleDeliveryRequest.setJsonPayload(requestPayload.toJson());
    http:Response response = check deliveryClient->post("schedule", scheduleDeliveryRequest);
    test:assertEquals(response.statusCode, 201);
    DeliveryScheduledRecord returnData = check (check response.getJsonPayload()).cloneWithType();

    response = check deliveryClient->get((returnData.id + 1).toString());
    test:assertEquals(response.statusCode, 404);
}

@test:Config {
    groups: ["delivery"]
}
function updateDeliveryTest() returns error? {
    http:Request scheduleDeliveryRequest = new;
    ScheduleDeliveryRequest requestPayload = {
        orderId: 1,
        pickUpAddress: "test pickup address",
        deliveryAddress: "test delivery address"
    };
    scheduleDeliveryRequest.setJsonPayload(requestPayload.toJson());
    http:Response response = check deliveryClient->post("schedule", scheduleDeliveryRequest);
    test:assertEquals(response.statusCode, 201);
    DeliveryScheduledRecord returnData = check (check response.getJsonPayload()).cloneWithType();
    string deliveryId = returnData.id.toString();

    response = check deliveryClient->put(deliveryId + "/update/pickedUp", ());
    test:assertEquals(response.statusCode, 200);
    DeliveryViewRecord returnData2 = check (check response.getJsonPayload()).cloneWithType();
    test:assertEquals(returnData2.status, PICKED_UP);
}