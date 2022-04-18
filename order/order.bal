import ballerina/sql;
import ballerinax/mysql;
import ballerina/http;
import ballerina/time;

configurable string USER = ?;   
configurable string PASSWORD = ?;
configurable string HOST = ?;
configurable int PORT = ?;
configurable string DATABASE = ?;
configurable string CONSUMER_ENDPOINT = ?;
configurable string RESTAURANT_ENDPOINT = ?;
configurable string MENU_ITEM_ENDPOINT = ?;
configurable string ACCOUNTING_ENDPOINT = ?;
configurable string DELIVERY_ENDPOINT = ?;


final mysql:Client dbClient = check new(host=HOST, user=USER, password=PASSWORD, port=PORT, database=DATABASE);
final http:Client consumerEndpoint = check new(CONSUMER_ENDPOINT);
final http:Client restaurantEndpoint = check new(RESTAURANT_ENDPOINT);
final http:Client menuItemEndpoint = check new(MENU_ITEM_ENDPOINT);
final http:Client accountingEndpoint = check new(ACCOUNTING_ENDPOINT);
final http:Client deliveryEndpoint = check new(DELIVERY_ENDPOINT);


enum OrderState {
    APPROVAL_PENDING = "APPROVAL_PENDING",
    APPROVED = "APPROVED",
    REJECTED = "REJECTED",
    ACCEPTED = "ACCEPTED",
    PREPARING = "PREPARING",
    READY_FOR_PICKUP = "READY_FOR_PICKUP",
    PICKED_UP = "PICKED_UP",
    DELIVERED = "DELIVERED",
    CANCELLED = "CANCELLED"
}

# Represents an order
type Order record {|
    # The ID of the order
    int id;
    # The consumer who placed the order
    Consumer consumer;
    # The restaurant with which the order was placed
    Restaurant restaurant;
    # The items contained within the order
    OrderItem[] orderItems;
    # The address to which the order should be delivered to
    string deliveryAddress;
    # The date and time and which the order should be delivered
    time:Civil deliveryTime;
    # The current status of the order
    OrderState status;
|};

# Represents and order item
type OrderItem record {|
    # The ID of the order item
    int id;
    # The menu item relevant to the order item
    MenuItem menuItem;
    # The quantity of menu items requested in the order item
    int quantity;
|};

# Represent a consumer
type Consumer record {
    # The ID of the consumer
    int id;
    # The name of the consumer
    string name;
    # The address of the consumer
    string address;
};

# Represents a restaurant
type Restaurant record {
    # The ID of the restaurant
    int id;
    # The name of the restaurant
    string name;
    # The address of the restaurant
    string address;
};

# Represents a menu item
type MenuItem record {
    # The ID of the menu item
    int id;
    # The name of the menu item
    string name;
    # The price of the menu item
    decimal price;
};

# Represents a single row of the `Orders` table
type OrderTableRow record {|
    # The id field of the row
    int id;
    # The consumerId field of the row
    int consumerId;
    # The restaurant field of the row
    int restaurantId;
    # The deliveryAddress field of the row
    string deliveryAddress;
    # The deliveryTime field of the row
    time:Civil deliveryTime;
    # The status field of the row
    string status;
|};


# Represents a single row of the `OrderItems` table
type OrderItemTableRow record {|
    # The id field of the row
    int id;
    # The menuItemId field of the row
    int menuItemId;
    # The quantity field of the row
    int quantity;
|};

# Creates a new order. This method does not create the underlying order items of the order
#
# + consumerId - The ID of the consumer who placed to order  
# + restaurantId - The ID of the restaurant with which the order was placed  
# + deliveryAddress - The address to which the order should be delivered  
# + deliveryTime - The date and time at which the order should be delivered
# + return - The details of the order if the creation was successful. An error if unsuccessful
isolated function createOrder(int consumerId, int restaurantId, string deliveryAddress, time:Civil deliveryTime) returns Order|error {
    sql:ExecutionResult result = check dbClient->execute(`
        INSERT INTO Orders (consumerId, restaurantId, deliveryAddress, deliveryTime, status) 
        VALUES (${consumerId}, ${restaurantId}, ${deliveryAddress}, ${deliveryTime}, ${APPROVAL_PENDING})
    `);
    int|string? generatedOrderId = result.lastInsertId;
    if generatedOrderId is string? {
        return error("Unable to retrieve generated ID of order.");
    }
    return <Order>{
        id: generatedOrderId,
        consumer: check getConsumerDetails(consumerId),
        restaurant: check getRestaurantDetails(restaurantId),
        orderItems: [],
        deliveryAddress: deliveryAddress,
        deliveryTime: deliveryTime,
        status: APPROVAL_PENDING
    };
}

# Creates an order item within a provided order
#
# + menuItemId - The ID of the menu item which corresponds to the order item  
# + quantity - The quantity of the provided menu item requested 
# + orderId - The order under which the order item should be created
# + return - The details of the order item if the creation was successful. An error if unsuccessful
isolated function createOrderItem(int menuItemId, int quantity, int orderId) returns OrderItem|error {
    MenuItem menuItem = check getMenuItem(menuItemId);

    string orderStatus = check dbClient->queryRow(`SELECT status from Orders WHERE id=${orderId}`);
    match orderStatus {
        APPROVED => {
            _ =  check changeOrderStatus(orderId, APPROVAL_PENDING);
        }
        APPROVAL_PENDING => {}
        _ => {
            return error("Cannot modify order");
        }
    }

    sql:ExecutionResult result = check dbClient->execute(`
        INSERT INTO OrderItems (menuItemId, quantity, orderId) 
        VALUES (${menuItemId}, ${quantity}, ${orderId})
    `);

    int|string? generatedOrderItemId = result.lastInsertId;
    if generatedOrderItemId is string? {
        return error("Unable to retrieve generated ID of order item.");
    }
    return <OrderItem>{
        id: generatedOrderItemId,
        menuItem: menuItem,
        quantity: quantity
    };
}

# Retrieves the details of an order
#
# + id - The ID of the order
# + return - The details of the order if the retrieval was successful. An error if unsuccessful
isolated function getOrder(int id) returns Order|error {
    OrderTableRow result = check dbClient->queryRow(`
        SELECT id, consumerId, restaurantId, deliveryAddress, deliveryTime, status
        FROM Orders WHERE id = ${id}
    `);
    return <Order>{
        id: id,
        consumer: check getConsumerDetails(result.consumerId),
        restaurant: check getRestaurantDetails(result.restaurantId),
        orderItems: check getOrderItems(id),
        deliveryAddress: result.deliveryAddress,
        deliveryTime: result.deliveryTime,
        status: <OrderState>result.status
    };
}

# Retrieves the details of an order item
#
# + id - The ID of the order item
# + return - The details of the order item if the retrieval was successful. An error if unsuccessful
isolated function getOrderItem(int id) returns OrderItem|error {
    OrderItemTableRow result = check dbClient->queryRow(`
        SELECT id, menuItemId, quantity
        FROM OrderItems WHERE id = ${id}
    `);
    return <OrderItem>{
        id: result.id,
        menuItem: check getMenuItem(result.menuItemId),
        quantity: result.quantity
    };
}

# Retrieves the details of the parent order to which a given order item belongs to
#
# + id - The ID of the order item
# + return - The details of the order if the retrieval was successful. An error if unsuccessful
isolated function getParentOrder(int id) returns Order|error {
    int orderId = check dbClient->queryRow(`SELECT orderId FROM OrderItems WHERE id=${id}`);
    return check getOrder(orderId);
}

# Deletes an order
#
# + id - The ID of the order to be deleted
# + return - The details of the order if the deletion was successful. An error if unsuccessful
isolated function removeOrder(int id) returns Order|error {
    Order 'order = check getOrder(id);
    _ = check dbClient->execute(`DELETE FROM Orders WHERE id = ${id}`);
    return 'order;
}

# Deletes an order item
#
# + id - The ID of the order item to be deleted
# + return - The details of the order item if the deletion was successful. An error if unsuccessful
isolated function removeOrderItem(int id) returns OrderItem|error {
    Order 'order = check getParentOrder(id);
    match 'order.status {
        APPROVED => {
            _ =  check changeOrderStatus('order.id, APPROVAL_PENDING);
        }
        APPROVAL_PENDING => {}
        _ => {
            return error("Cannot modify order");
        }
    }

    OrderItem orderItem = check getOrderItem(id);
    _ = check dbClient->execute(`DELETE FROM OrderItems WHERE id = ${id}`);
    return orderItem;
}

# Retrieves the list of order items contained within an order
#
# + orderId - The ID of the order for which the order items need to be retrieved
# + return - An array of order items if the retrievals was successful. An error if unsuccessful
isolated function getOrderItems(int orderId) returns OrderItem[]|error {
    OrderItem[] orderItems = [];
    stream<OrderItemTableRow, error?> resultStream = dbClient->query(`
        SELECT id, menuItemId, quantity 
        FROM OrderItems WHERE orderId = ${orderId}
    `);
    check from OrderItemTableRow orderItem in resultStream
        do {
            orderItems.push({
                id: orderItem.id,
                menuItem: check getMenuItem(orderItem.menuItemId),
                quantity: orderItem.quantity
            });
        };
    check resultStream.close();
    return orderItems;
}

# Changes the status of an order
#
# + orderId - The ID of the order for which the status needs to be changed  
# + newStatus - The state to which the status needs to be changed to
# + return - The details of the order if the status change was successful. An error if unsuccessful
isolated function changeOrderStatus(int orderId, OrderState newStatus) returns Order|error {
    _ = check dbClient->execute(`UPDATE Orders SET status=${newStatus.toString()} WHERE id = ${orderId}`);

    Order 'order = check getOrder(orderId);
    if newStatus is READY_FOR_PICKUP {
        http:Request deliveryScheduleRequest = new;
        deliveryScheduleRequest.setJsonPayload({
            orderId: orderId,
            pickUpAddress: 'order.restaurant.address,
            deliveryAddress: 'order.consumer.address
        });
        _ = check deliveryEndpoint->post("schedule", deliveryScheduleRequest, targetType = json);
    }

    return 'order;
}

# Confirms the order by the consumer
#
# + orderId - The ID of the order which needs to be confirmed
# + return - The details of the order if the confimration was successful. An error if unsuccessful
isolated function confirmOrder(int orderId) returns Order|error {
    string orderStatus = check dbClient->queryRow(`SELECT status from Orders WHERE id=${orderId}`);
    if orderStatus != APPROVAL_PENDING {
        return error("Cannot confirm an order that is not in the 'APPROVAL_PENDING' state");
    }

    Order 'order = check getOrder(orderId);

    decimal orderTotal = 0;
    foreach OrderItem orderItem in 'order.orderItems {
        orderTotal += orderItem.menuItem.price;
    }

    http:Request consumerValidateRequest = new;
    consumerValidateRequest.setJsonPayload({
        orderId: orderId,
        orderAmount: orderTotal
    });
    _ = check consumerEndpoint->post('order.consumer.id.toString() + "/validate", consumerValidateRequest, targetType = json);

    http:Request accountingChargeRequest = new;
    accountingChargeRequest.setJsonPayload({
        consumerId: 'order.consumer.id,
        orderId: orderId,
        orderAmount: orderTotal
    });
    _ = check accountingEndpoint->post("charge", accountingChargeRequest, targetType = json);

    http:Request createTicketRequest = new;
    createTicketRequest.setJsonPayload({
        orderId: orderId
    });
    _ = check restaurantEndpoint->post('order.restaurant.id.toString() + "/ticket", createTicketRequest, targetType = json);

    'order = check changeOrderStatus(orderId, APPROVED);
    return 'order;
}

# Retrieves the details of a consumer
#
# + consumerId - The ID of the consumer for which the detailes are required
# + return - The details of the customer if the retrieval was successful. An error if unsuccessful
isolated function getConsumerDetails(int consumerId) returns Consumer|error {
    Consumer consumer = check consumerEndpoint->get(consumerId.toString());
    return <Consumer>{
        id: consumerId,
        name: consumer.name,
        address: consumer.address
    };
}

# Retrieves the details of a restaurant
#
# + restaurantId - The ID of the restaurant for which the details are required
# + return - The details of the restaurant if the retrieval was successful. An error if unsuccessful
isolated function getRestaurantDetails(int restaurantId) returns Restaurant|error {
    Restaurant restaurant = check restaurantEndpoint->get(restaurantId.toString());
    return <Restaurant>{
        id: restaurantId,
        name: restaurant.name,
        address: restaurant.address
    };
}

# Retrieves the details of a menu item
#
# + menuItemId - The ID of the menu item for which the detailes are required
# + return - The details of the menu item if the retrieval was successful. An error if unsuccessful
isolated function getMenuItem(int menuItemId) returns MenuItem|error {
    MenuItem menuItem = check menuItemEndpoint->get(menuItemId.toString());
    return <MenuItem>{
        id: menuItemId,
        name: menuItem.name,
        price: menuItem.price
    };
}
