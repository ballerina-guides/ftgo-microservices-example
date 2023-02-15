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

type ConsumerCreatedRecord record {|
    *Consumer;
    *http:Links;
|};

type ConsumerViewRecord record {|
    *Consumer;
    *http:Links;
|};

http:Client consumerClient = check new("http://localhost:8080/consumer/");

@test:Config {
    groups: ["create-consumer"]
 }
 function createConsumerTest1() returns error? {
    http:Request createConsumerRequest = new;
    createConsumerRequest.setJsonPayload({
        name: "Test Name",
        address: "Test address",
        email: "test@email.com"
    });
    http:Response response = check consumerClient->post("", createConsumerRequest);
    test:assertEquals(response.statusCode, 201);

    ConsumerCreatedRecord returnData = check (check response.getJsonPayload()).cloneWithType();
    test:assertEquals(returnData.name, "Test Name");
    test:assertEquals(returnData.address, "Test address");
    test:assertEquals(returnData.email, "test@email.com");
    test:assertEquals(returnData._links.length(), 3);
}

@test:Config {
    groups: ["create-consumer"]
}
function createConsumerTest2() returns error? {
    http:Request createConsumerRequest = new;
    createConsumerRequest.setJsonPayload({
        name: "Test Name",
        address: "Test address",
        email: "test@email.com",
        additionalField: "additional field"
    });
    http:Response response = check consumerClient->post("", createConsumerRequest);
    test:assertEquals(response.statusCode, 201);

    ConsumerCreatedRecord returnData = check (check response.getJsonPayload()).cloneWithType();
    test:assertEquals(returnData.name, "Test Name");
    test:assertEquals(returnData.address, "Test address");
    test:assertEquals(returnData.email, "test@email.com");
    test:assertEquals(returnData._links.length(), 3);
}

@test:Config {
    groups: ["create-consumer"]
} 
function createConsumerNegativeTest1() returns error? {
    http:Request createConsumerRequest = new;
    createConsumerRequest.setJsonPayload({
        name: "Test Name",
        address: "Test address"
    });
    http:Response response = check consumerClient->post("", createConsumerRequest);
    test:assertEquals(response.statusCode, 400);
}

@test:Config {
    groups: ["get-consumer"]
} 
function getConsumerTest() returns error? {
    http:Request createConsumerRequest = new;
    createConsumerRequest.setJsonPayload({
        name: "Test Name2",
        address: "Test address2",
        email: "test2@email.com"
    });
    ConsumerCreatedRecord createdConsumer = check consumerClient->post("", createConsumerRequest);

    http:Response response = check consumerClient->get(createdConsumer.id.toString());
    test:assertEquals(response.statusCode, 200);

    ConsumerCreatedRecord returnData = check (check response.getJsonPayload()).cloneWithType();
    test:assertEquals(returnData.name, "Test Name2");
    test:assertEquals(returnData.address, "Test address2");
    test:assertEquals(returnData.email, "test2@email.com");
    test:assertEquals(returnData._links.length(), 3);
}

@test:Config {
    groups: ["get-consumer"]
} 
function getConsumerNegativeTest() returns error? {
    http:Request createConsumerRequest = new;
    createConsumerRequest.setJsonPayload({
        name: "Test Name2",
        address: "Test address2",
        email: "test2@email.com"
    });
    ConsumerCreatedRecord createdConsumer = check consumerClient->post("", createConsumerRequest);

    http:Response response = check consumerClient->get((createdConsumer.id + 1).toString());
    test:assertEquals(response.statusCode, 404);
    test:assertEquals(response.getJsonPayload(), { message: "Consumer cannot be found." });
}

@test:Config {
    groups: ["delete-consumer"]
} 
function deleteConsumerTest() returns error? {
    http:Request createConsumerRequest = new;
    createConsumerRequest.setJsonPayload({
        name: "Test Name2",
        address: "Test address2",
        email: "test2@email.com"
    });
    ConsumerCreatedRecord createdConsumer = check consumerClient->post("", createConsumerRequest);

    http:Response response = check consumerClient->get(createdConsumer.id.toString());
    test:assertEquals(response.statusCode, 200);

    response = check consumerClient->delete(createdConsumer.id.toString());
    test:assertEquals(response.statusCode, 200);

    response = check consumerClient->get(createdConsumer.id.toString());
    test:assertEquals(response.statusCode, 404);
}

@test:Config {
    groups: ["delete-consumer"]
} 
function deleteConsumerNegativeTest() returns error? {
    http:Request createConsumerRequest = new;
    createConsumerRequest.setJsonPayload({
        name: "Test Name2",
        address: "Test address2",
        email: "test2@email.com"
    });
    ConsumerCreatedRecord createdConsumer = check consumerClient->post("", createConsumerRequest);

    http:Response response = check consumerClient->delete((createdConsumer.id + 1).toString());
    test:assertEquals(response.statusCode, 404);
    test:assertEquals(response.getJsonPayload(), { message: "Consumer cannot be found." });
}

@test:Config {
    groups: ["update-consumer"]
} 
function updateConsumerTest() returns error? {
    http:Request createConsumerRequest = new;
    createConsumerRequest.setJsonPayload({
        name: "Test Name2",
        address: "Test address2",
        email: "test2@email.com"
    });
    ConsumerCreatedRecord createdConsumer = check consumerClient->post("", createConsumerRequest);

    http:Request updateConsumerRequest = new;
    updateConsumerRequest.setJsonPayload({
        name: "Test Name3",
        address: "Test address3",
        email: "test3@email.com"
    });
    http:Response response = check consumerClient->put(createdConsumer.id.toString(), updateConsumerRequest);
    test:assertEquals(response.statusCode, 200);
    
    ConsumerCreatedRecord returnData = check (check response.getJsonPayload()).cloneWithType();
    test:assertEquals(returnData.name, "Test Name3");
    test:assertEquals(returnData.address, "Test address3");
    test:assertEquals(returnData.email, "test3@email.com");
    test:assertEquals(returnData._links.length(), 3);
}

@test:Config {
    groups: ["update-consumer"]
} 
function updateConsumerNegativeTest() returns error? {
    http:Request createConsumerRequest = new;
    createConsumerRequest.setJsonPayload({
        name: "Test Name2",
        address: "Test address2",
        email: "test2@email.com"
    });
    ConsumerCreatedRecord createdConsumer = check consumerClient->post("", createConsumerRequest);

    http:Request updateConsumerRequest = new;
    updateConsumerRequest.setJsonPayload({
        name: "Test Name3",
        address: "Test address3",
        email: "test3@email.com"
    });
    http:Response response = check consumerClient->put((createdConsumer.id + 1).toString(), updateConsumerRequest);
    test:assertEquals(response.statusCode, 404);
    test:assertEquals(response.getJsonPayload(), { 
        message: "Consumer cannot be found." 
    });
}

@test:Config {
    groups: ["validate-order"]
} 
function validateOrderTest() returns error? {
    http:Request validateOrderRequest = new;
    validateOrderRequest.setJsonPayload({
        orderId: 1,
        orderAmount: 10.66
    });
    http:Response response = check consumerClient->post("1/validate", validateOrderRequest);
    test:assertEquals(response.statusCode, 200);
    test:assertEquals(response.getJsonPayload(), {
        message: "Order has been validated."
    });
}
