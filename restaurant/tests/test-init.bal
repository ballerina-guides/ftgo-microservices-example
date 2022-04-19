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

    _ = check dbClient->execute(`CREATE DATABASE IF NOT EXISTS Restaurant;`);
    _ = check dbClient->execute(`
        CREATE TABLE IF NOT EXISTS Restaurant.Restaurants (
            id      INTEGER         AUTO_INCREMENT PRIMARY KEY,
            name    VARCHAR(255)    NOT NULL,
            address VARCHAR(255)    NOT NULL
        );
    `);
    _ = check dbClient->execute(`
        CREATE TABLE IF NOT EXISTS Restaurant.Menus (
            id              INTEGER AUTO_INCREMENT PRIMARY KEY,
            name            VARCHAR(255) NOT NULL,
            restaurantId    INTEGER NOT NULL,
            FOREIGN KEY (restaurantId) REFERENCES Restaurant.Restaurants(id) ON DELETE CASCADE
        );
    `);
    _ = check dbClient->execute(`
        CREATE TABLE IF NOT EXISTS Restaurant.MenuItems (
            id      INTEGER         AUTO_INCREMENT PRIMARY KEY,
            name    VARCHAR(255)    NOT NULL,
            price   DECIMAL(10,2)   NOT NULL,
            menuId  INTEGER         NOT NULL,
            FOREIGN KEY (menuId) REFERENCES Restaurant.Menus(id) ON DELETE CASCADE
        );
    `);
    _ = check dbClient->execute(`
        CREATE TABLE IF NOT EXISTS Restaurant.Tickets (
            id              INTEGER         AUTO_INCREMENT PRIMARY KEY,
            restaurantId    INTEGER         NOT NULL,
            orderId         INTEGER         NOT NULL,
            status          VARCHAR(25)     NOT NULL,
            FOREIGN KEY (restaurantId) REFERENCES Restaurant.Restaurants(id) ON DELETE CASCADE
        );
    `);

}
