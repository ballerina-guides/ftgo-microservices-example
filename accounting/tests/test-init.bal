import ballerina/test;
import ballerinax/mysql;

@test:BeforeSuite
function databaseInit() returns error? {
    mysql:Client dbClient = check new(host = HOST, port = PORT, user = USER, password = PASSWORD);

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

