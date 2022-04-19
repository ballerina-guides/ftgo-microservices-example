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

    CourierCreatedRecord returnData = check (check response.getJsonPayload()).cloneWithType();

    response = check courierClient->get((returnData.id + 1).toString());
    test:assertEquals(response.statusCode, 404);
}
