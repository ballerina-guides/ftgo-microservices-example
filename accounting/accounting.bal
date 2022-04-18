import ballerina/sql;
import ballerinax/mysql;
import ballerina/http;

configurable string USER = ?;   
configurable string PASSWORD = ?;
configurable string HOST = ?;
configurable int PORT = ?;
configurable string DATABASE = ?;
configurable string CONSUMER_ENDPOINT = ?;
configurable string RESTAURANT_ENDPOINT = ?;
configurable string ORDER_ENDPOINT = ?;

final mysql:Client dbClient = check new(host=HOST, user=USER, password=PASSWORD, port=PORT, database=DATABASE);
final http:Client consumerEndpoint = check new(CONSUMER_ENDPOINT);
final http:Client restaurantEndpoint = check new(RESTAURANT_ENDPOINT);
final http:Client orderEndpoint = check new(ORDER_ENDPOINT);

# Represents a bill
type Bill record {|
    # The ID of the bill
    int id;
    # The consumer with which the bill is associated with
    Consumer consumer;
    # The order with which the bill is associated with
    Order 'order;
    # The total amount of the order
    decimal orderAmount;
|};

# Represents a consumer
type Consumer record {
    # The ID of the consumer
    int id;
    # The name of the consumer
    string name;
    # The email address of the consumer
    string email;
};

# Represents an order
type Order record {
    # The ID of the order
    int id;
    # The items contained within the order
    OrderItem[] orderItems;
};

# Represents an order item
type OrderItem record {
    # The ID of the order item
    int id;
    # The menu item that the order is associated with
    MenuItem menuItem;
    # The quantity of the menu item present in the order
    int quantity;
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

# Represents a row in the `Bills` table
type BillTableRow record {|
    # The `ID` field of the row
    int id;
    # The `consumerId` field of the row
    int consumerId;
    # The `orderID` field of the row
    int orderId;
    # The `orderAmount` field of the row
    decimal orderAmount;
|};

# Creates a new bill
#
# + consumerId - The ID of the consumer with which the bill is associated  
# + orderId - The ID of the order with which the bill is associated  
# + orderAmount - The amount of the order
# + return - The details of the bill if the creation was successful. An error if unsuccessful
public isolated function createBill(int consumerId, int orderId, decimal orderAmount) returns Bill|error {
    sql:ExecutionResult result = check dbClient->execute(`
        INSERT INTO bills (consumerId, orderId, orderAmount) 
        VALUES (${consumerId}, ${orderId}, ${orderAmount})
    `);

    int|string? generatedBillId = result.lastInsertId;
    if generatedBillId is string? {
        return error("Unable to retrieve generated ID of bill");
    }

    return <Bill>{
        id: generatedBillId,
        consumer: check getConsumerDetails(consumerId),
        'order: check getOrderDetails(orderId),
        orderAmount: orderAmount
    };
}

# Retrieves the details of a bill
#
# + id - The ID of the bill to be retrieved
# + return - The details of the bill if the retrieval was successful. An error if unsuccessful
public isolated function getBill(int id) returns Bill|error {
    BillTableRow result = check dbClient->queryRow(`
        SELECT id, consumerId, orderId, orderAmount
        FROM bills WHERE id = ${id}
    `);
    return <Bill>{
        id: id,
        consumer: check getConsumerDetails(result.consumerId),
        'order: check getOrderDetails(result.orderId),
        orderAmount: result.orderAmount
    };
}

# Charges a consumer a certain amount from their account. This is a mock function and does not perform any practical functionalities.
#
# + consumerId - The ID of the consumer to be charged  
# + orderAmount - The amount to be charged from the consumer.
# + return - `()` if the charge was successful. An error if unsuccessful.
public isolated function chargeConsumer(int consumerId, decimal orderAmount) returns error? {
    // Implement logic
    return;
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
        email: consumer.email
    };
}

# Retrieves the details of an order
#
# + orderId - The ID of the order for which the detailes are required
# + return - The details of the order if the retrieval was successful. An error if unsuccessful
isolated function getOrderDetails(int orderId) returns Order|error {
    Order 'order = check orderEndpoint->get(orderId.toString());
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
