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

import ballerina/http;
import ballerina/sql;
import ballerina/time;

# The request body to be used when creating an order
type CreateOrderRequest record {|
    # The ID of the consumer creating the order
    int consumerId;
    # The ID of the restaurant to which the order is being placed
    int restaurantId;
    # The address to which the order should be delivered to
    string deliveryAddress;
    # The date and time at which the order should be delivered
    time:Civil deliveryTime;
    # The items in the order
    CreateOrderItemRequest[] orderItems; 
|};

# Representation of an order item to be used when creating an order
type CreateOrderItemRequest record {|
    # The ID of the menu item
    int menuItemId;
    # The quantity of the item required in the order
    int quantity;
|};

# Response for a successful order creation
type OrderCreated record {|
    *http:Created;
    # Details of the created order along with the links to manage it
    record {|
        *Order;
        *http:Links;
    |} body;
|};

# Response for a successful order item creation
type OrderItemCreated record {|
    *http:Created;
    # Details of the created order item along with the links to manage it
    record {|
        *OrderItem;
        *http:Links;
    |} body;
|};

# Response for a successful order update
type OrderUpdated record {|
    *http:Ok;
    # Details of the created order along with the links to manage it
    record {|
        *Order;
        *http:Links;
    |} body;
|};

# Error response for when the requested order cannot be found
type OrderNotFound record {|
    *http:NotFound;
    # Error message
    readonly record {} body = { 
        "message": "Order cannot be found." 
    };
|};

# Error response for when the requested order item cannot be found
type OrderItemNotFound record {|
    *http:NotFound;
    # Error message
    readonly record {} body = { 
        "message": "Order item cannot be found." 
    };
|};

# Response for a successful order retrieval
type OrderView record {|
    *http:Ok;
    # Details of the retrieved order along with the HTTP links to manage it
    record {|
        *Order;
        *http:Links;
    |} body;
|};

# Response for a successful order deletion
type OrderDeleted record {|
    *http:Ok;
    # Details of the deleted order
    Order body;
|};

# Response for a successful order item deletion
type OrderItemDeleted record {|
    *http:Ok;
    # Details of the deleted order item
    OrderItem body;
|};

# Response for a successful creation of an order
type OrderConfirmed record {|
    *http:Ok;
    # Details of the confirmed order
    Order body;
|};

# Represents an unexpected error
type InternalError record {|
   *http:InternalServerError;
    # Error payload
    record {| 
        string message;
    |} body;
|}; 


# Description
service /'order on new http:Listener(8082) {

    # Resource function to create a new order
    #
    # + request - Details of the order to be created. This can also contain information regarding the order items within the order
    # + return - `OrderCreated` if the order was successfully created.
    #            `InternalError` if an unexpected error occurs
    isolated resource function post .(@http:Payload CreateOrderRequest request) returns OrderCreated|InternalError  {
        do {
            transaction {
                Order generatedOrder = check createOrder(request.consumerId, request.restaurantId, request.deliveryAddress, request.deliveryTime);

                foreach CreateOrderItemRequest orderItem in request.orderItems {
                    OrderItem generatedOrderItem = check createOrderItem(orderItem.menuItemId, orderItem.quantity, generatedOrder.id);
                    generatedOrder.orderItems.push(generatedOrderItem);
                }

                check commit;

                return <OrderCreated>{ 
                    headers: {
                        location: "/order/" + generatedOrder.id.toString()
                    },
                    body: {
                        ...generatedOrder,
                        _links: getOrderLinks(generatedOrder.id)
                    }
                };
            }
        } on fail error e {
            return <InternalError>{ body: { message: e.message() }};
        }
    }

    # Resource function to retrieve the details of an order
    #
    # + id - The ID of the requested order
    # + return - `OrderView` if the details are successfully fetched.
    #            `OrderNotFound` if an order with the provided ID was not found.
    #            `InternalError` if an unexpected error occurs
    isolated resource function get [int id]() returns OrderView|OrderNotFound|InternalError {
        do {
            Order 'order = check getOrder(id);
            return <OrderView>{ 
                body: {
                    ...'order,
                    _links: getOrderLinks(id)
                }
            };
        } on fail error e {
            if e is sql:NoRowsError {
                return <OrderNotFound>{};
            }
            return <InternalError>{ body: { message: e.message() }};
        } 
    }

    # Resource function to add an order item to an existing order
    #
    # + orderId - The ID of the order to which the item should be added  
    # + request - The details of the order item to be added
    # + return - `OrderItemCreated` if the menu item was sucessfully created.
    #            `InternalError` if an unexpected error occurs
    isolated resource function post [int orderId]/item(@http:Payload CreateOrderItemRequest request) returns OrderItemCreated|InternalError {
        do {
            OrderItem generatedOrderItem = check createOrderItem(request.menuItemId, request.quantity, orderId);
            return <OrderItemCreated>{ 
                body: {
                    ...generatedOrderItem,
                    _links: getOrderItemLinks(generatedOrderItem.id, orderId)
                } 
            };
        } on fail error e {
            return <InternalError>{ body: { message: e.message() }};
        } 
    }

    # Resource function to delete an order
    #
    # + id - The ID of the order to be deleted
    # + return - `OrderDeleted` if the order was successfully deleted.
    #            `OrderNotFound` if a order with the provided ID was not found.
    #            `InternalError` if an unexpected error occurs
    isolated resource function delete [int id]() returns OrderDeleted|OrderNotFound|InternalError {
        do {
            Order 'order = check removeOrder(id);
            return <OrderDeleted> { body: 'order };
        } on fail error e {
            if e is sql:NoRowsError {
                return <OrderNotFound>{};
            }
            return <InternalError>{ body: { message: e.message() }};
        } 
    }

    # Resource function to remove an order item from an existing order
    #
    # + orderId - The ID of the order from which the item should be removed  
    # + id - The ID of the order item to be removed
    # + return - `OrderItemDeleted` if the order item was successfully deleted.
    #            `OrderItemNotFound` if a order item with the provided ID was not found.
    #            `InternalError` if an unexpected error occurs
    isolated resource function delete [int orderId]/orderItem/[int id]() returns OrderItemDeleted|OrderItemNotFound|InternalError {
        do {
            OrderItem orderItem = check removeOrderItem(id);
            return <OrderItemDeleted> { body: orderItem };
        } on fail error e {
            if e is sql:NoRowsError {
                return <OrderItemNotFound>{};
            }
            return <InternalError>{ body: { message: e.message() }};
        } 
    }

    # Resource function to confirm a placed order
    #
    # + id - The ID of the order to be confirmed
    # + return - `OrderConfirmed` if the order was successfully confirmed.
    #            `OrderNotFound` if a order with the provided ID was not found.
    #            `InternalError` if an unexpected error occurs
    isolated resource function get [int id]/confirm() returns OrderConfirmed|OrderNotFound|InternalError {
        do {
            Order 'order = check confirmOrder(id);
            return <OrderConfirmed> { body: 'order };
        } on fail error e {
            if e is sql:NoRowsError {
                return <OrderNotFound>{};
            }
            return <InternalError>{ body: { message: e.message() }};
        }
    }

    # Resource function to update the status a placed order
    #
    # + id - The ID of the order to be confirmed
    # + return - `OrderConfirmed` if the order was successfully confirmed.
    #            `OrderNotFound` if a order with the provided ID was not found.
    #            `InternalError` if an unexpected error occurs
    isolated resource function put [int id]/updateStatus/[string newStatus]() returns OrderUpdated|OrderNotFound|InternalError {
        do {
            Order 'order = check changeOrderStatus(id, <OrderState>newStatus);
            return <OrderUpdated> { 
                body: {
                    ...'order,
                    _links: getOrderLinks(id) 
                }
            };
        } on fail error e {
            if e is sql:NoRowsError {
                return <OrderNotFound>{};
            }
            return <InternalError>{ body: { message: e.message() }};
        }
    }
}

# Obtain the HTTP links related to a given order
#
# + orderId - The ID of the order
# + return - An array of links
isolated function getOrderLinks(int orderId) returns map<http:Link> {
    return {
        "view": {
            rel: "view",
            href: "/order/" + orderId.toString(),
            methods: [http:GET]
        },
        "update": {
            rel: "update",
            href: "/order/" + orderId.toString(),
            methods: [http:PUT]
        },
        "delete": {
            rel: "delete",
            href: "/order/" + orderId.toString(),
            methods: [http:DELETE]
        }
    };
}

# Obtain the HTTP links related to a given order item
#
# + orderItemId - The ID of the order item  
# + parentOrderId - The ID of the order to which the order item belong
# + return - An array of links
isolated function getOrderItemLinks(int orderItemId, int parentOrderId) returns map<http:Link> {
    return {
        "view": {
            rel: "view",
            href: "/order/" + parentOrderId.toString() + "/item/" + orderItemId.toString(),
            methods: [http:GET]
        },
        "update": {
            rel: "update",
            href: "/order/" + parentOrderId.toString() + "/item/" + orderItemId.toString(),
            methods: [http:PUT]
        },
        "delete": {
            rel: "delete",
            href: "/order/" + parentOrderId.toString() + "/item/" + orderItemId.toString(),
            methods: [http:DELETE]
        },
        "parent order": {
            rel: "parent order",
            href: "/order/" + parentOrderId.toString(),
            methods: [http:GET]
        }
    };
}
