//
//  ViewModelMetadataTests.swift
//  AsyncFlowExampleTests
//
//  Created by jimmy on 2026. 1. 3.
//

import AsyncFlow
@testable import AsyncFlowExample
import Testing

@MainActor
@Suite("ViewModel Metadata Tests")
struct ViewModelMetadataTests {
    @Test("BaseScreenViewModel - 자동 메타데이터 생성")
    func autoMetadataGeneration() async throws {
        // Given
        let viewModel = A_1ViewModel(depth: 0)

        // When
        let metadata = viewModel.metadata

        // Then
        #expect(metadata.identifier == "A_1ViewModel")
        #expect(metadata.displayName == "A-1")
    }

    @Test("다양한 ViewModel - 메타데이터 변환 규칙")
    func metadataConversionRules() async throws {
        // Given
        let vm1 = A_2ViewModel(depth: 1)
        let vm2 = B_3ViewModel(depth: 2)
        let vm3 = A_5ViewModel(depth: 4)

        // When & Then
        #expect(vm1.metadata.displayName == "A-2")
        #expect(vm2.metadata.displayName == "B-3")
        #expect(vm3.metadata.displayName == "A-5")
    }

    @Test("ModalViewModel - 메타데이터 생성")
    func modalViewModelMetadata() async throws {
        // Given
        let viewModel = ModalViewModel()

        // When
        let metadata = viewModel.metadata

        // Then
        #expect(metadata.identifier == "ModalViewModel")
        #expect(metadata.displayName.contains("Modal"))
    }

    @Test("모든 Tab A ViewModels - 메타데이터 고유성")
    func tabAViewModelsUniqueness() async throws {
        // Given
        let vms = [
            A_1ViewModel(depth: 0),
            A_2ViewModel(depth: 1),
            A_3ViewModel(depth: 2),
            A_4ViewModel(depth: 3),
            A_5ViewModel(depth: 4),
        ]

        // When
        let identifiers = vms.map { $0.metadata.identifier }
        let displayNames = vms.map { $0.metadata.displayName }

        // Then: 모든 identifier와 displayName이 고유해야 함
        #expect(Set(identifiers).count == 5)
        #expect(Set(displayNames).count == 5)

        // displayName 형식 확인
        #expect(displayNames == ["A-1", "A-2", "A-3", "A-4", "A-5"])
    }

    @Test("모든 Tab B ViewModels - 메타데이터 고유성")
    func tabBViewModelsUniqueness() async throws {
        // Given
        let vms = [
            B_1ViewModel(depth: 0),
            B_2ViewModel(depth: 1),
            B_3ViewModel(depth: 2),
            B_4ViewModel(depth: 3),
            B_5ViewModel(depth: 4),
        ]

        // When
        let identifiers = vms.map { $0.metadata.identifier }
        let displayNames = vms.map { $0.metadata.displayName }

        // Then
        #expect(Set(identifiers).count == 5)
        #expect(Set(displayNames).count == 5)

        // displayName 형식 확인
        #expect(displayNames == ["B-1", "B-2", "B-3", "B-4", "B-5"])
    }
}
