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
import ballerinax/mysql.driver as _;

# Represents a consumer
public type Consumer record {|
    # The ID of the consumer
    int id;
    # The name of the consumer
    string name;
    # The address of the consumer
    string address;
    # The email address of the consumer
    string email;
|};

configurable string user = ?;
configurable string password = ?;
configurable string host = ?;
configurable int port = ?;
configurable string database = ?;

final mysql:Client dbClient = check new(host = host, user = user, password = password, port = port, database = database);

# Creates a new consumer
#
# + name - The name of the consumer  
# + address - The address of the consumer  
# + email - The email address of the consumer
# + return - The details of the consumer if the creation was successful. An error if unsuccessful
isolated function createConsumer(string name, string address, string email) returns Consumer|error {
    sql:ExecutionResult result = check dbClient->execute(`INSERT INTO Consumers (name, address, email) VALUES (${name}, ${address}, ${email})`);
    int|string? generatedConsumerId = result.lastInsertId;
    if generatedConsumerId is string? {
        return error("Unable to retrieve generated ID of consumer.");
    }
    
    return <Consumer>{
        id: generatedConsumerId,
        name: name,
        address: address,
        email: email
    };
}

# Retrieves the details of a consumer
#
# + consumerId - The ID of the requested consumer
# + return - The details of the consumer if the retrieval was successful. An error if unsuccessful
isolated function getConsumer(int consumerId) returns Consumer|error {
    return check dbClient->queryRow(`SELECT id, name, address, email FROM Consumers WHERE id = ${consumerId}`);
}

# Deletes a consumer
#
# + consumerId - The ID of the consumer
# + return - The details of the deleted consumer if the deletion was successful. An error if unsuccessful 
isolated function deleteConsumer(int consumerId) returns Consumer|error {
    Consumer consumer = check getConsumer(consumerId);
    _ = check dbClient->execute(`DELETE FROM Consumers WHERE id = ${consumerId}`);
    return consumer;
}

# Updates the details of a customer
#
# + id - The ID of the consumer to be updated  
# + name - The updated name of the consumer  
# + address - The updated address of the consumer  
# + email - The updated email address of the consumer
# + return - The details of the consumer if the update was successful. An error if unsuccessful
isolated function updateConsumer(int id, string name, string address, string email) returns Consumer|error {
    _ = check dbClient->execute(`UPDATE Consumers SET name=${name}, address=${address}, email=${email} WHERE id = ${id}`);
    return getConsumer(id);
}
