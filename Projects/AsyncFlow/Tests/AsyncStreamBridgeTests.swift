//
//  AsyncStreamBridgeTests.swift
//  AsyncFlowTests
//
//  Created by 정준영 on 2025. 12. 29.
//

@testable import AsyncFlow
import Foundation
import Testing

@Suite("AsyncStreamBridge Tests")
struct AsyncStreamBridgeTests {
    @Test("단일 구독자가 값을 정상적으로 수신하는지 확인")
    @MainActor
    func singleSubscriber() async {
        let bridge = AsyncStreamBridge<Int>()

        let stream = bridge.stream

        let task = Task {
            var receivedValues: [Int] = []
            for await value in stream {
                receivedValues.append(value)
            }
            return receivedValues
        }

        bridge.yield(1)
        bridge.yield(2)
        bridge.yield(3)
        bridge.finish()

        let receivedValues = await task.value

        #expect(receivedValues == [1, 2, 3])
    }

    @Test("다중 구독자(Multicast)가 값을 모두 수신하는지 확인")
    @MainActor
    func multipleSubscribers() async {
        let bridge = AsyncStreamBridge<String>()

        let stream1 = bridge.stream
        let stream2 = bridge.stream

        let task1 = Task<[String], Never> {
            var values: [String] = []
            for await value in stream1 {
                values.append(value)
            }
            return values
        }

        let task2 = Task<[String], Never> {
            var values: [String] = []
            for await value in stream2 {
                values.append(value)
            }
            return values
        }

        bridge.yield("A")
        bridge.yield("B")
        bridge.finish()

        let result1 = await task1.value
        let result2 = await task2.value

        #expect(result1 == ["A", "B"])
        #expect(result2 == ["A", "B"])
    }

    @Test("구독 취소 시 다른 구독자에게 영향이 없는지 확인")
    @MainActor
    func subscriptionCancellation() async {
        let bridge = AsyncStreamBridge<Int>()
        let stream1 = bridge.stream
        let stream2 = bridge.stream

        let task1 = Task<[Int], Never> {
            var values: [Int] = []
            for await value in stream1 {
                values.append(value)
                break
            }
            return values
        }

        let task2 = Task<[Int], Never> {
            var values: [Int] = []
            for await value in stream2 {
                values.append(value)
            }
            return values
        }

        bridge.yield(1)
        bridge.yield(2)
        bridge.finish()

        let result1 = await task1.value
        let result2 = await task2.value

        #expect(result1 == [1])
        #expect(result2 == [1, 2])
    }
}
