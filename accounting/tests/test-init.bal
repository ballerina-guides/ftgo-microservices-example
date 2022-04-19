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
import ballerinax/mysql;

@test:BeforeSuite
function databaseInit() returns error? {
    mysql:Client dbClient = check new(host = host, port = port, user = user, password = password);

    _ = check dbClient->execute(`CREATE DATABASE IF NOT EXISTS Accounting;`);
    _ = check dbClient->execute(`
        CREATE TABLE IF NOT EXISTS Accounting.bills (
            id          INTEGER         AUTO_INCREMENT PRIMARY KEY,
            consumerId  INTEGER         NOT NULL,
            orderId     INTEGER         NOT NULL,
            orderAmount DECIMAL(10,2)   NOT NULL
        );
    `);
}

@test:Mock { functionName: "getConsumerDetails" }
test:MockFunction mockGetConsumerDetails = new();

@test:Mock { functionName: "getOrderDetails" }
test:MockFunction mockGetOrderDetails = new();

@test:BeforeSuite
function setExternalAPICalls() returns error? {
    test:when(mockGetConsumerDetails).withArguments(1).thenReturn(<Consumer>{
        id: 1,
        name: "Test Consumer",
        email: "test@test.com"
    });

    test:when(mockGetOrderDetails).withArguments(1).thenReturn(<Order>{
        id: 1,
        orderItems: [
            { 
                id: 1,
                menuItem: { id: 2, name: "food", price: 10.50},
                quantity: 5
            },
            { 
                id: 2,
                menuItem: { id: 3, name: "drink", price: 20.50},
                quantity: 6
            }
        ]
    });

    test:when(mockGetConsumerDetails).thenReturn(error("Consumer not found."));
    test:when(mockGetOrderDetails).thenReturn(error("Consumer not found."));
}

