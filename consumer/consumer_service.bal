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

# Request body to be used when creating and updating a consumer
type ConsumerRequest record {
    # Name of the consumer
    string name;
    # Address of the consumer
    string address;
    # Email address of the consumer
    string email;
};

# Response for a successful consumer creation
type ConsumerCreated record {|
    *http:Created;
    # Details of the created consumer along with the HTTP links to manage it
    record {|
        *Consumer;
        *http:Links;
    |} body;
|};

# Response for a successful consumer retrieval
type ConsumerView record {|
    *http:Ok;
    # Details of the retrieved consumer along with the HTTP links to manage it
    record {|
        *Consumer;
        *http:Links;
    |} body;
|};

# Error response for when the requested consumer cannot be found
type ConsumerNotFound record {|
    *http:NotFound;
    # Error message
    readonly record {} body = { 
        "message": "Consumer cannot be found." 
    };
|};

# Response for a successful consumer deletion
type ConsumerDeleted record {|
    *http:Ok;
    # Details of the deleted consumer
    Consumer body;
|};

# Response for a successful consumer update
type ConsumerUpdated record {|
    *http:Ok;
    # Details of the updated consumer along with the HTTP links to manage it
    record {|
        *Consumer;
        *http:Links;
    |} body;
|};

# Request body to be used when validating an order placed by a consumer
type ValidateOrderRequest record {|
    # The ID of the order placed
    int orderId;
    # The total amount of the order
    decimal orderAmount;
|};

# Response for a successful order validation
type OrderValidated record {|
    *http:Ok;
    # Response body
    readonly record {} body = { 
        "message": "Order has been validated." 
    };
|};

# Represents an unexpected error
type InternalError record {|
   *http:InternalServerError;
   # Error payload
    record {| 
        string message;
    |} body;
|}; 

@http:ServiceConfig { cors: { allowOrigins: ["*"] } }
service /consumer on new http:Listener(8080) {

    # Resource function to create a new consumer
    #
    # + request - Details of the consumer to be created
    # + return - `ConsumerCreated` if the consumer was sucessfully created.
    #            `InternalError` if an unexpected error occurs.
    isolated resource function post .(@http:Payload ConsumerRequest request) returns ConsumerCreated|InternalError {
        do {
            Consumer generatedConsumer = check createConsumer(request.name, request.address, request.email);
            return <ConsumerCreated>{ 
                headers: {
                    location: "/consumer/" + generatedConsumer.id.toString()
                },
                body: {
                    ...generatedConsumer,
                    _links: getLinks(generatedConsumer.id)
                }
            };
        } on fail error e {
            return <InternalError>{ body: { message: e.message() }};
        }
    }

    # Resource function to fetch the details of a consumer
    #
    # + id - The ID of the requested consumer
    # + return - `ConsumerView` if the details are successfully fetched.
    #            `ConsumerNotFound` if a consumer with the provided ID was not found.
    #            `InternalError` if an unexpected error occurs
    isolated resource function get [int id]() returns ConsumerView|ConsumerNotFound|InternalError {
        do {
            Consumer consumer = check getConsumer(id);
            return <ConsumerView>{ 
                body: {
                    ...consumer,
                    _links: getLinks(consumer.id)
                }
            };
        } on fail error e {
            if e is sql:NoRowsError {
                return <ConsumerNotFound>{};
            }
            return <InternalError>{ body: { message: e.message() }};
        }       
    }

    # Resource function to delete a consumer
    #
    # + id - The ID of the consumer to be deleted
    # + return - `ConsumerDeleted` if the consumer was successfully deleted.
    #            `ConsumerNotFound` if a consumer with the provided ID was not found.
    #            `InternalError` if an unexpected error occurs
    isolated resource function delete [int id]() returns ConsumerDeleted|ConsumerNotFound|InternalError {
        do {
            Consumer consumer = check deleteConsumer(id);
            return <ConsumerDeleted>{ body: consumer};
        } on fail error e {
            if e is sql:NoRowsError {
                return <ConsumerNotFound>{};
            }
            return <InternalError>{ body: { message: e.message() }};
        }       
    }

    # Resource function to update the details of the consumer
    #
    # + id - The ID of the consumer to be updated  
    # + request - Details of the consumer to be updated
    # + return - `ConsumerUpdated` if the consumer was successfully updated.
    #            `InternalError` if an unexpected error occurs
    isolated resource function put [int id](@http:Payload ConsumerRequest request) returns ConsumerUpdated|ConsumerNotFound|InternalError {
        do {
            Consumer updatedConsumer = check updateConsumer(id, request.name, request.address, request.email);
            return <ConsumerUpdated>{ 
                body: {
                    ...updatedConsumer,
                    _links: getLinks(updatedConsumer.id)
                }
            };
        } on fail error e {
            if e is sql:NoRowsError {
                return <ConsumerNotFound>{};
            }
            return <InternalError>{ body: { message: e.message() }};
        }       
    }

    # Resource function to validate an order placed by a consumer. This function is a placeholder and does not perform any meaningful actions
    #
    # + id - The ID of consumer who placed the order
    # + request - The details of the order
    # + return - `OrderValidated` if the validation was successful.
    #            `InternalError` if an unexpected error occurs
    isolated resource function post [int id]/validate(@http:Payload ValidateOrderRequest request) returns OrderValidated|InternalError {
        // Implement logic
        return <OrderValidated>{};
    }
        
}

# Returns the HTTP links related to a given consumer
#
# + consumerId - The ID of the consumer
# + return - An array of links
isolated function getLinks(int consumerId) returns map<http:Link> {
    map<http:Link> links = {};

    links["view"] = {
        rel: "view",
        href: "/consumer/" + consumerId.toString(),
        methods: [http:GET]
    };

    links["update"] = {
        rel: "update",
        href: "/consumer/" + consumerId.toString(),
        methods: [http:PUT]
    };

    links["delete"] = {
        rel: "delete",
        href: "/consumer/" + consumerId.toString(),
        methods: [http:DELETE]
    };

    return links;
}
