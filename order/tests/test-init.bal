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
import ballerinax/mysql;

@test:BeforeSuite
function databaseInit() returns error? {
    mysql:Client dbClient = check new(host = host, port = port, user = user, password = password);

    _ = check dbClient->execute(`CREATE DATABASE IF NOT EXISTS Orders;`);
    _ = check dbClient->execute(`
        CREATE TABLE IF NOT EXISTS Orders.Orders (
            id              INTEGER AUTO_INCREMENT PRIMARY KEY,
            consumerId      INTEGER NOT NULL,
            restaurantId    INTEGER NOT NULL,
            deliveryAddress VARCHAR(255) NOT NULL,
            deliveryTime    TIMESTAMP NOT NULL,
            status          VARCHAR(20) NOT NULL
        );
    `);
    _ = check dbClient->execute(`
        CREATE TABLE IF NOT EXISTS Orders.OrderItems (
            id              INTEGER AUTO_INCREMENT PRIMARY KEY,
            menuItemId      INTEGER NOT NULL,
            quantity        INTEGER NOT NULL,
            orderId         INTEGER NOT NULL,
            FOREIGN KEY (orderId) REFERENCES Orders.Orders(id) ON DELETE CASCADE,
            CONSTRAINT chk_quantity CHECK (quantity > 0)
        );
    `);
}

@test:Mock { functionName: "getConsumerDetails" }
test:MockFunction mockGetConsumerDetails = new();

@test:Mock { functionName: "getRestaurantDetails" }
test:MockFunction mockGetRestaurantDetails = new();

@test:Mock { functionName: "getMenuItem" }
test:MockFunction mockGetMenuItem = new();

public client class MockConsumersEndpointClient {

    remote function get(string path, map<string|string[]>? headers = (), http:TargetType targetType = http:Response) returns http:Response| http:PayloadType | http:ClientError {
        http:Response response = new;
        response.statusCode = 200;
        response.setJsonPayload({
            id: 1,
            name: "Test Consumer",
            address: "Test Address"
        });
        return response;
    }
}

@test:BeforeSuite
function setExternalAPICalls() returns error? {
    test:when(mockGetConsumerDetails).withArguments(1).thenReturn(<Consumer>{
        id: 1,
        name: "Test Consumer",
        address: "Test Address"
    });

    test:when(mockGetRestaurantDetails).withArguments(1).thenReturn(<Restaurant>{
        id: 1,
        name: "Test Restaurant",
        address: "Test Address"
    });

    test:when(mockGetMenuItem).withArguments(1).thenReturn(<MenuItem>{
        id: 1,
        name: "Test MenuItem1",
        price: 50.53
    });

    test:when(mockGetMenuItem).withArguments(2).thenReturn(<MenuItem>{
        id: 2,
        name: "Test MenuItem2",
        price: 83.12
    });

    test:when(mockGetConsumerDetails).thenReturn(error("Consumer not found."));
}
