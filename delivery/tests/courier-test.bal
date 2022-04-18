import ballerina/test;
import ballerina/log;
import ballerina/http;

type CourierCreatedRecord record {|
    *Courier;
    *http:Links;
|};

http:Client courierClient = check new("http://localhost:8084/courier/");

@test:Config {
    groups: ["create-courier"]
}
function createCourierTest() returns error? {
    http:Request createCourierRequest = new;
    CourierRequest requestPayload = {
        name: "Test courier"
    };
    createCourierRequest.setJsonPayload(requestPayload.toJson());
    http:Response response = check courierClient->post("", createCourierRequest);
    test:assertEquals(response.statusCode, 201);

    log:printInfo((check response.getJsonPayload()).toJsonString());
    CourierCreatedRecord returnData = check (check response.getJsonPayload()).cloneWithType();
    test:assertEquals(returnData.name, requestPayload.name);
    test:assertEquals(returnData.links.length(), 1);
}

@test:Config {
    groups: ["create-courier"]
}
function createCourierNegativeTest() returns error? {
    http:Request createCourierRequest = new;
    record {} requestPayload = {
        "namex": "Test courier"
    };
    createCourierRequest.setJsonPayload(requestPayload.toJson());
    http:Response response = check courierClient->post("", createCourierRequest);
    test:assertEquals(response.statusCode, 400);
}

@test:Config {
    groups: ["get-courier"]
}
function getCourierTest() returns error? {
    http:Request createCourierRequest = new;
    CourierRequest requestPayload = {
        name: "Test courier2"
    };
    createCourierRequest.setJsonPayload(requestPayload.toJson());
    http:Response response = check courierClient->post("", createCourierRequest);
    test:assertEquals(response.statusCode, 201);

    log:printInfo((check response.getJsonPayload()).toJsonString());
    CourierCreatedRecord returnData = check (check response.getJsonPayload()).cloneWithType();

    response = check courierClient->get(returnData.id.toString());
    test:assertEquals(response.statusCode, 200);

    returnData = check (check response.getJsonPayload()).cloneWithType();
    test:assertEquals(returnData.name, requestPayload.name);
    test:assertEquals(returnData.links.length(), 1);
}

@test:Config {
    groups: ["get-courier"]
}
function getCourierNegativeTest() returns error? {
    http:Request createCourierRequest = new;
    CourierRequest requestPayload = {
        name: "Test courier3"
    };
    createCourierRequest.setJsonPayload(requestPayload.toJson());
    http:Response response = check courierClient->post("", createCourierRequest);
    test:assertEquals(response.statusCode, 201);

    log:printInfo((check response.getJsonPayload()).toJsonString());
    CourierCreatedRecord returnData = check (check response.getJsonPayload()).cloneWithType();

    response = check courierClient->get((returnData.id + 1).toString());
    test:assertEquals(response.statusCode, 404);
}