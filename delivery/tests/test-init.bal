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
    _ = check dbClient->execute(`CREATE DATABASE IF NOT EXISTS Delivery;`);
    _ = check dbClient->execute(`
        CREATE TABLE IF NOT EXISTS Delivery.Couriers (
            id      INTEGER     AUTO_INCREMENT PRIMARY KEY,
            name    VARCHAR(50) NOT NULL
        )
    `);
    _ = check dbClient->execute(`
        CREATE TABLE IF NOT EXISTS Delivery.Deliveries (
            id              INTEGER         AUTO_INCREMENT PRIMARY KEY,
            orderId         INTEGER         NOT NULL,
            courierId       INTEGER         NOT NULL,
            pickUpAddress   VARCHAR(255)    NOT NULL,
            pickUpTime      TIMESTAMP,
            deliveryAddress VARCHAR(255)    NOT NULL,
            deliveryTime    TIMESTAMP,
            status          VARCHAR(25)     NOT NULL,
            FOREIGN KEY (courierId) REFERENCES Delivery.Couriers(id) ON DELETE CASCADE
        )
    `);
}

@test:Mock { functionName: "getOrderDetails" }
test:MockFunction mockGetOrderDetails = new();

@test:Mock { functionName: "updateOrderStatus" }
test:MockFunction mockUpdateOrderStatus = new();

@test:BeforeSuite
function setExternalAPICalls() returns error? {
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

    test:when(mockGetOrderDetails).thenReturn(error("Order not found."));
    test:when(mockUpdateOrderStatus).thenReturn(());
}

