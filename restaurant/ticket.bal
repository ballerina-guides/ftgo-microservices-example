import ballerina/sql;
import ballerina/log;

enum TicketState {
    ACCEPTED = "ACCEPTED",
    PREPARING = "PREPARING",
    READY_FOR_PICKUP = "READY_FOR_PICKUP",
    PICKED_UP = "PICKED_UP"
}

# Represents a ticket
type Ticket record {|
    # The ID of the ticket
    int id;
    # The restaurant associated with the ticket
    Restaurant restaurant;
    # The order associated with the ticket
    Order 'order;
    # The current state of the ticket
    TicketState status;
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

# Creates a new ticket.
# 
# + restaurantId - The ID of the restaurant associated with the ticket  
# + orderId - The ID of the order associated with the ticket
# + return - The details of the ticket if the creation was successful. An error if unsuccessful
isolated function createTicket(int restaurantId, int orderId) returns Ticket|error {
    sql:ExecutionResult result = check dbClient->execute(`INSERT INTO Tickets (restaurantId, orderId, status) VALUES (${restaurantId}, ${orderId}, ${ACCEPTED})`);
    int|string? generatedTicketId = result.lastInsertId;
    if generatedTicketId is string? {
        return error("Unable to retrieve generated ID of ticket.");
    }

    return <Ticket>{
        id: generatedTicketId,
        restaurant: check getRestaurant(restaurantId),
        'order: check getOrderDetails(orderId),
        status: ACCEPTED
    };
}

# Retrives a ticket.
# 
# + id - The ID of the ticket  
# + return - The details of the ticket if the retrieval was successful. An error if unsuccessful
isolated function getTicket(int id) returns Ticket|error {
    record {|
        int id;
        int restaurantId;
        int orderId;
        string status;
    |} ticketRow = check dbClient->queryRow(`SELECT id, restaurantId, orderId, status FROM Tickets WHERE id=${id}`);

    return <Ticket>{
        id: ticketRow.id,
        restaurant: check getRestaurant(ticketRow.restaurantId),
        'order: check getOrderDetails(ticketRow.orderId),
        status: <TicketState>ticketRow.status
    };
}

# Updates the status of a  ticket.
# 
# + id - The ID of the ticket to be updated
# + newStatus - The status to be changed to  
# + return - The details of the ticket if the update was successful. An error if unsuccessful
isolated function updateTicket(int id, TicketState newStatus) returns Ticket|error {
    _ = check dbClient->execute(`UPDATE Tickets SET status=${newStatus} WHERE id=${id}`);
    Ticket ticket = check getTicket(id);
    log:printInfo(ticket.'order.id.toString() + "/updateStatus/" + newStatus.toString());
    _ = check orderEndpoint->put(ticket.'order.id.toString() + "/updateStatus/" + newStatus.toString(), message = (), targetType = json);
    return ticket;
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
