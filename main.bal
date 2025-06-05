import ballerina/http;
import ballerina/log;
import ballerina/os;
import ballerinax/redis;

configurable string redisHost = "valkey-5ea3cd2c57084489bfc3d82bd90520b2-t11308238643-choreo-org.b.aivencloud.com";
configurable int redisPort = 28398;
configurable string redisPassword = os:getEnv("AVNS_VTx_b6mi0U6L3JAuf7e");

configurable string awsRedisHost = "valkey-5ea3cd2c57084489bfc3d82bd90520b2-t22708512358-choreo-org.b.aivencloud.com";
configurable int awsRedisPort = 28398;
configurable string awsRedisPassword = os:getEnv("AVNS_qNQCXj1X_68ipBz-baS");

configurable string selfHostedRedisHost = "valkey-5ea3cd2c57084489bfc3d82bd90520b2-t31908193083-choreo-org.b.aivencloud.com";
configurable int selfHostedRedisPort = 28398;
configurable string selfHostedRedisPassword = os:getEnv("AVNS_KkAvPIVfjDQlmXI7pdM");

redis:SecureSocket redisSecureSocket = {
    verifyMode: redis:FULL
};

redis:ConnectionConfig redisConfig = {
    connection: {
        host: redisHost,
        port: redisPort,
        password: redisPassword,
        options: {
            connectionTimeout: 5
        }
    },
    connectionPooling: true,
    secureSocket: redisSecureSocket
};

redis:ConnectionConfig awsRedisConfig = {
    connection: {
        host: awsRedisHost,
        port: awsRedisPort,
        password: awsRedisPassword,
        options: {
            connectionTimeout: 5
        }
    },
    connectionPooling: true,
    secureSocket: redisSecureSocket
};

redis:ConnectionConfig selfHostedRedisConfig = {
    connection: {
        host: selfHostedRedisHost,
        port: selfHostedRedisPort,
        password: selfHostedRedisPassword,
        options: {
            connectionTimeout: 5
        }
    },
    connectionPooling: true
};

redis:Client redisClient = check new (redisConfig);
redis:Client awsRedisClient = check new (awsRedisConfig);
redis:Client selfHostedRedisClient = check new (selfHostedRedisConfig);

listener http:Listener httpListener = check new (2020);

service / on httpListener {
    resource function get cache\-item() returns http:Ok|http:InternalServerError {
        string message = "Hello, World!";
        string?|error cachedMessage = redisClient->get("hello");
        if cachedMessage is error {
            log:printError("Error getting cache key", cachedMessage);
        } else if cachedMessage is () {
            log:printInfo("Cache miss");
            string|error? setError = redisClient->set("hello", "Hello, World!, Cached");
            if setError is error {
                log:printError("Error setting cache key", setError);
            }
        } else {
            message = <string>cachedMessage;
            log:printInfo("Cache hit");
        }
        return <http:Ok>{
            body: message
        };
    }

    resource function get aws\-cache\-item() returns http:Ok|http:InternalServerError {
        string message = "Hello, World!";
        string?|error cachedMessage = awsRedisClient->get("hello");
        if cachedMessage is error {
            log:printError("Error getting cache key from AWS Redis", cachedMessage);
        } else if cachedMessage is () {
            log:printInfo("AWS Redis cache miss");
            string|error? setError = awsRedisClient->set("hello", "Hello, World!, Cached from AWS");
            if setError is error {
                log:printError("Error setting AWS Redis cache key", setError);
            }
        } else {
            message = <string>cachedMessage;
            log:printInfo("AWS Redis cache hit");
        }
        return <http:Ok>{
            body: message
        };
    }

    resource function get self\-hosted\-cache\-item() returns http:Ok|http:InternalServerError {
        string message = "Hello, World!";
        string?|error cachedMessage = selfHostedRedisClient->get("hello");
        if cachedMessage is error {
            log:printError("Error getting self-hosted cache key", cachedMessage);
        } else if cachedMessage is () {
            log:printInfo("Self-hosted cache miss");
            string|error? setError = selfHostedRedisClient->set("hello", "Hello, World!, Cached from Self-Hosted Redis");
            if setError is error {
                log:printError("Error setting self-hosted cache key", setError);
            }
        } else {
            message = <string>cachedMessage;
            log:printInfo("Self-hosted cache hit");
        }
        return <http:Ok>{
            body: message
        };
    }

    resource function post clear\-cache() returns http:Ok|http:InternalServerError {
        int|error? deleteError = redisClient->del(["hello"]);
        if deleteError is error {
            log:printError("Error deleting cache key", deleteError);
        } else {
            log:printInfo("Cache key deleted successfully");
        }
        return <http:Ok>{
            body: "Cache cleared"
        };
    }

    resource function post aws\-clear\-cache() returns http:Ok|http:InternalServerError {
        int|error? deleteError = awsRedisClient->del(["hello"]);
        if deleteError is error {
            log:printError("Error deleting AWS Redis cache key", deleteError);
        } else {
            log:printInfo("AWS Redis cache key deleted successfully");
        }
        return <http:Ok>{
            body: "AWS Redis cache cleared"
        };
    }
}
