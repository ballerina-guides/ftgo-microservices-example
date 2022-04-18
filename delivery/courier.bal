import ballerina/sql;

# Represents a courier
type Courier record {|
    # The ID of the courier
    int id;
    # The name of the courier
    string name;
|};

# Creates a courier
#
# + name - The name of the courier
# + return - The details of the courier if the creation was successful. An error if unsuccessful
isolated function createCourier(string name) returns Courier|error {
    sql:ExecutionResult result = check dbClient->execute(`INSERT INTO Couriers (name) VALUES (${name})`);
    int|string? generatedCourierId = result.lastInsertId;
    if generatedCourierId is string? {
        return error("Unable to retrieve generated ID of courier.");
    }

    return <Courier>{
        id: generatedCourierId,
        name: name
    };
}

# Retrieves the details of a courier
#
# + id - The ID of the courier
# + return - The details of the courier if the retrieval was successful. An error if unsuccessful
isolated function getCourier(int id) returns Courier|error {
    return check dbClient->queryRow(`SELECT id, name FROM Couriers WHERE id=${id}`);
}

# Determines the most suitable courier to carry out an order. At the moment, this method simply selects a random courier from the list of available couriers
#
# + pickUpAddres - The address from which the order should be picked up
# + return - The details of the courier if the search was successful. An error if unsuccessful
isolated function getAvailableCourier(string pickUpAddres) returns Courier|error {
    return check dbClient->queryRow(`SELECT id, name FROM Couriers ORDER BY RAND() LIMIT 1;`);
}