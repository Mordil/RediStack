//===----------------------------------------------------------------------===//
//
// This source file is part of the RediStack open source project
//
// Copyright (c) 2019 RediStack project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of RediStack project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import NIO

// MARK: Get

extension NewRedisCommand {
    /// Get the value of a key, converting it to the desired type.
    ///
    /// [https://redis.io/commands/get](https://redis.io/commands/get)
    /// - Parameters:
    ///     - key: The key to fetch the value from.
    ///     - type: The desired type to convert the stored data to.
    @inlinable
    public static func get<StoredType: RESPValueConvertible>(
        _ key: RedisKey,
        as type: StoredType.Type
    ) -> NewRedisCommand<StoredType?> {
        let args = [RESPValue(bulk: key)]
        return .init(keyword: "GET", arguments: args)
    }

    /// Gets the values of all specified keys, using `.null` to represent non-existant values.
    ///
    /// See [https://redis.io/commands/mget](https://redis.io/commands/mget)
    /// - Parameter keys: The list of keys to fetch the values from.
    public static func mget(_ keys: [RedisKey]) -> NewRedisCommand<[RESPValue]> {
        let args = keys.map(RESPValue.init)
        return .init(keyword: "MGET", arguments: args)
    }
}

// MARK: Set

extension NewRedisCommand {
    /// Append a value to the end of an existing entry.
    /// - Note: If the key does not exist, it is created and set as an empty string, so `APPEND` will be similar to `SET` in this special case.
    ///
    /// See [https://redis.io/commands/append](https://redis.io/commands/append)
    /// - Parameters:
    ///     - value: The value to append onto the value stored at the key.
    ///     - key: The key to use to uniquely identify this value.
    @inlinable
    public static func append<Value: RESPValueConvertible>(_ value: Value, to key: RedisKey) -> NewRedisCommand<Int> {
        let args: [RESPValue] = [
            .init(bulk: key),
            value.convertedToRESPValue()
        ]
        return .init(keyword: "APPEND", arguments: args)
    }
    
    /// Sets the value stored in the key provided, overwriting the previous value.
    ///
    /// Any previous expiration set on the key is discarded if the SET operation was successful.
    ///
    /// - Important: Regardless of the type of value stored at the key, it will be overwritten to a string value.
    ///
    /// [https://redis.io/commands/set](https://redis.io/commands/set)
    /// - Parameters:
    ///     - key: The key to use to uniquely identify this value.
    ///     - value: The value to set the key to.
    @inlinable
    public static func set<Value: RESPValueConvertible>(_ key: RedisKey, to value: Value) -> NewRedisCommand<String> {
        let args: [RESPValue] = [
            .init(bulk: key),
            value.convertedToRESPValue()
        ]
        return .init(keyword: "SET", arguments: args)
    }

    /// Sets each key to their respective new value, overwriting existing values.
    /// - Note: Use `msetnx(_:)` if you don't want to overwrite values.
    ///
    /// See [https://redis.io/commands/mset](https://redis.io/commands/mset)
    /// - Parameter operations: The key-value list of SET operations to execute.
    @inlinable
    public static func mset<Value: RESPValueConvertible>(_ operations: [RedisKey: Value]) -> NewRedisCommand<String> {
        return ._mset(command: "MSET", operations)
    }

    /// Sets each key to their respective new value, only if all keys do not currently exist.
    /// - Note: Use `mset(_:)` if you don't care about overwriting values.
    ///
    /// See [https://redis.io/commands/msetnx](https://redis.io/commands/msetnx)
    /// - Parameter operations: The key-value list of SET operations to execute.
    @inlinable
    public static func msetnx<Value: RESPValueConvertible>(_ operations: [RedisKey: Value]) -> NewRedisCommand<Int> {
        return ._mset(command: "MSETNX", operations)
    }
    
    @usableFromInline
    internal static func _mset<Value: RESPValueConvertible, ReturnType: RESPValueConvertible>(
        command: String,
        _ operations: [RedisKey: Value]
    ) -> NewRedisCommand<ReturnType> {
        assert(operations.count > 0, "At least 1 key-value pair should be provided.")

        let args: [RESPValue] = operations.reduce(
            into: .init(initialCapacity: operations.count * 2),
            { (array, element) in
                array.append(.init(bulk: element.key))
                array.append(element.value.convertedToRESPValue())
            }
        )
        
        return .init(keyword: command, arguments: args)
    }
}

// MARK: Increment

extension NewRedisCommand {
    /// Increments the stored value by the amount desired.
    ///
    /// See [https://redis.io/commands/incr](https://redis.io/commands/incr)
    /// - Parameters:
    ///     - key: The key whose value should be incremented.
    ///     - amount: The optional amount to increment the value by.
    @inlinable
    public static func incrby<Value>(_ key: RedisKey, amount: Value) -> NewRedisCommand<Int>
        where Value: SignedInteger & RESPValueConvertible
    {
        let args: [RESPValue] = [
            .init(bulk: key),
            .init(bulk: amount)
        ]
        return .init(keyword: "INCRBY", arguments: args)
    }

    /// Increments the stored value by the amount desired.
    ///
    /// See [https://redis.io/commands/incrbyfloat](https://redis.io/commands/incrbyfloat)
    /// - Parameters:
    ///     - key: The key whose value should be incremented.
    ///     - amount: The amount that this value should be incremented, supporting both positive and negative values.
    @inlinable
    public static func incrbyfloat<Value>(_ key: RedisKey, amount: Value) -> NewRedisCommand<Value>
        where Value: BinaryFloatingPoint & RESPValueConvertible
    {
        let args: [RESPValue] = [
            .init(bulk: key),
            amount.convertedToRESPValue()
        ]
        return .init(keyword: "INCRBYFLOAT", arguments: args)
    }
}

// MARK: Decrement

extension NewRedisCommand {
    /// Decrements the stored value by 1.
    ///
    /// See [https://redis.io/commands/decr](https://redis.io/commands/decr)
    /// - Parameter key: The key whose value should be decremented.
    public static func decr(_ key: RedisKey) -> NewRedisCommand<Int> {
        let args = [RESPValue(bulk: key)]
        return .init(keyword: "DECR", arguments: args)
    }

    /// Decrements the stored valye by the amount desired.
    ///
    /// See [https://redis.io/commands/decrby](https://redis.io/commands/decrby)
    /// - Parameters:
    ///     - key: The key whose value should be decremented.
    ///     - amount: The amount that this value should be decremented, supporting both positive and negative values.
    @inlinable
    public static func decrby<Value>(_ key: RedisKey, amount: Value) -> NewRedisCommand<Int>
        where Value: SignedInteger & RESPValueConvertible
    {
        let args: [RESPValue] = [
            .init(bulk: key),
            .init(bulk: amount)
        ]
        return .init(keyword: "DECRBY", arguments: args)
    }
}
