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

import ballerina/sql;
import ballerinax/mysql;
import ballerina/time;
import ballerina/http;
import ballerinax/mysql.driver as _;

enum DeliveryState {
    READY_FOR_PICKUP = "READY_FOR_PICKUP",
    PICKED_UP = "PICKED_UP",
    DELIVERED = "DELIVERED"
}

# Represents a delivery
type Delivery record {|
    # The ID of the delivery  
    int id;
    # The order associated with the delivery  
    Order 'order;
    # The courier assigned to to carry out the delivery  
    Courier courier;
    # The address of the retaurant from which the order should be picked up  
    string pickUpAddress;
    # The timestamp at which the order was picked up. `()` if the order is not yet picked up
    time:Civil? pickUpTime;
    # The address to which the order should be delivered to  
    string deliveryAddress;
    # The timestamp at which the order was delivered. `()` if the order is not yet delivered   
    time:Civil? deliveryTime;
    # The current status of the delivery
    DeliveryState status;
|};

# Represents an order
type Order record {
    # The ID of the order
    int id;
    # The items contained within the order
    OrderItem[] orderItems;
};

# Represents and order item
type OrderItem record {
    # The ID of the order item
    int id;
    # The menu item relevant to the order item
    MenuItem menuItem;
    # The quantity of menu items requested in the order item
    int quantity;
};

# Represents a menu item
type MenuItem record {|
    # The ID of the menu item
    int id;
    # The name of the menu item
    string name;
    # The price of the menu item
    decimal price;
|};

configurable string user = ?;   
configurable string password = ?;
configurable string host = ?;
configurable int port = ?;
configurable string database = ?;
configurable string orderEndpoint = ?;

final mysql:Client dbClient = check new(host = host, user = user, password = password, port = port, database = database);
final http:Client orderClient = check new(orderEndpoint);

# Schedules a delivery
#
# + orderId - The ID of the order associated with the delivery  
# + pickUpAddress - The address from which the order should be picked up
# + deliveryAddress - The address to which the order should be delivered to
# + return - The details of the delivery if the scheduling was successful. An error if unsuccessful
isolated function scheduleDelivery(int orderId, string pickUpAddress, string deliveryAddress) returns Delivery|error {
    Courier availableCourier = check getAvailableCourier(pickUpAddress);
    sql:ExecutionResult result = check dbClient->execute(`
        INSERT INTO Deliveries (orderId, courierId, pickUpAddress, deliveryAddress, status) 
        VALUES (${orderId}, ${availableCourier.id}, ${pickUpAddress}, ${deliveryAddress}, ${READY_FOR_PICKUP})
    `);
    int|string? generatedDeliveryId = result.lastInsertId;
    if generatedDeliveryId is string? {
        return error("Unable to retrieve generated ID of delivery.");
    }

    return <Delivery>{
        id: generatedDeliveryId,
        'order: check getOrderDetails(orderId),
        courier: availableCourier,
        pickUpAddress: pickUpAddress,
        pickUpTime: (),
        deliveryAddress: deliveryAddress,
        deliveryTime: (),
        status: READY_FOR_PICKUP
    };
}

# Retrives the details of a delivery
#
# + id - The ID of the delivery
# + return - The details of the delivery if the retrieval was successful. An error if unsuccessful
isolated function getDelivery(int id) returns Delivery|error {
    record {|
        int id;
        int orderId;
        int courierId;
        string pickUpAddress;
        time:Civil? pickUpTime;
        string deliveryAddress;
        time:Civil? deliveryTime;
        string status;
    |} deliveryRow = check dbClient->queryRow(`
        SELECT id, orderId, courierId, pickUpAddress, pickUpTime, deliveryAddress, deliveryTime, status 
        FROM Deliveries 
        WHERE id=${id}
    `);

    return <Delivery>{
        id: deliveryRow.id,
        'order: check getOrderDetails(deliveryRow.orderId),
        courier: check getCourier(deliveryRow.courierId),
        pickUpAddress: deliveryRow.pickUpAddress,
        pickUpTime: deliveryRow.pickUpTime,
        deliveryAddress: deliveryRow.deliveryAddress,
        deliveryTime: deliveryRow.deliveryTime,
        status: <DeliveryState>deliveryRow.status
    };
}

# Updates the status of a delivery
#
# + id - The ID of the delivery  
# + newStatus - The status to which the delivery should be updated to
# + return - The details of the delivery if the update  was successful. An error if unsuccessful
isolated function updateDelivery(int id, DeliveryState newStatus) returns Delivery|error {
    _ = check dbClient->execute(`UPDATE Deliveries SET status=${newStatus} WHERE id=${id}`);

     if newStatus is PICKED_UP {
        _  = check dbClient->execute(`UPDATE Deliveries SET pickUpTime=${time:utcNow()} WHERE id=${id}`);
    }

    if newStatus is DELIVERED {
        _  = check dbClient->execute(`UPDATE Deliveries SET deliveryTime=${time:utcNow()} WHERE id=${id}`);
    }

    Delivery delivery = check getDelivery(id);
    check updateOrderStatus(delivery, newStatus);
    return delivery;
}

# Retrieves the details of an order
#
# + orderId - The ID of the order for which the details are required
# + return - The details of the order if the retrieval was successful. An error if unsuccessful
isolated function getOrderDetails(int orderId) returns Order|error {
    Order 'order = check orderClient->get(orderId.toString());
    OrderItem[] orderItems = [];

    foreach OrderItem orderItem in 'order.orderItems {
        orderItems.push(<OrderItem>{
            id: orderItem.id,
            menuItem: {
                id: orderItem.menuItem.id,
                name: orderItem.menuItem.name,
                price: orderItem.menuItem.price
            },
            quantity: orderItem.quantity
        });
    }

    return <Order>{
        id: orderId,
        orderItems: orderItems
    };
}

isolated function updateOrderStatus(Delivery delivery, DeliveryState newStatus) returns error? {
    _ = check orderClient->put(delivery.'order.id.toString() + "/updateStatus/" + newStatus.toString(), message = (), targetType = json);
    return ();
}
